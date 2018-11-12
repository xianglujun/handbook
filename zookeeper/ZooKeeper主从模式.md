# ZooKeeper主从模式

## 主节点
只有一个主进程会成为主节点, 因此一个进程在成为主节点之后, 必须获得`ZooKeeper`的管理权限.

可以通过如下步骤:
- 所有的进程都去同时创建一个`/master`节点
- 当个第一个主节点创建成功之后, 其他进程会创建失败
- 失败进程创建时候后, 监听`/master`节点的通知
- 当`/master`发出删除的通知时, 则创建`/master`节点（循环以上步骤）

## 从节点、任务、分配
主要包括了三个节点`/workers`,`/assign`,`/tasks`，这三个节点可能会在主进程分配任务的时候进行创建. 无论这三个znode何时被创建, 都需要主进程对这三个znode的状态进行监听。

## 从节点
1. 从节点首先要通知主节点, 告知从节点可以执行任务。

从节点通过在`/workers`下创建子`zone`临时节点来进行通知。 并在子节点中使用主机名来标识自己。
```sh
create -e /workers/worker1.example.com "worker1.example.com:2224"
```
其中第二个参数用来标识从节点的地址.


2. 从节点需要在`/assign`创建一个子节点, 用来接收主节点的任务分配。
```java
create -e /assign/worker1.example.com ""

# 接收从节点的任务分配
ls /assign/worker1.example.com true
```

## 客户端
客户端在发布任务以后, 主节点需要分配任务给从节点, 具体经理一下步骤：
1. 客户端创建任务
```sh
create -s /tasks/task- "cmd"

out: Created /tasks/task-0000000000
```
我们需要按照任务的顺序来创建任务, 其本质上是一个队列.

2. 客户端监听任务是否执行完成
```sh
ls /tasks/task-0000000000 true
```

3. 主节点监听任务新增状态
```sh
WATCHER::
WatchedEvent state:SyncConnected type:NodeChildrenChanged path:/tasks
```

当主节点在检测到有新任务之后, 会将任务分配到具体的从节点执行

4. 主节点检查可用的从节点, 并将任务分配给从节点
```sh
# 查询任务列表
ls /tasks

# 查询可用的从节点
ls /workers

# 分配任务节点
create /assign/worker1.example.com/task-0000000000 ""
```

5. 从节点接到新任务的通知
```sh
WATCHER::
WatchedEvent state:SyncConnected type:NodeChildrenChanged
path:/assign/worker1.example.com
```

6. 检查任务列表
```sh
ls /assign/worker1.example.com
```

7. 从节点更新任务状态
```sh
create /tasks/task-0000000000/status "done"
```

8. 客户端会监听对应的任务节点状态变更, 并获取任务节点
```sh
WATCHER::
WatchedEvent state:SyncConnected type:NodeChildrenChanged
path:/tasks/task-0000000000

# 查看任务的详情
get /tasks/task-0000000000

out:
"cmd"
cZxid = 0x7c
ctime = Tue Dec 11 10:30:18 CET 2012
mZxid = 0x7c
mtime = Tue Dec 11 10:30:18 CET 2012
pZxid = 0x7e
cversion = 1
dataVersion = 0
aclVersion = 0
ephemeralOwner = 0x0
dataLength = 5
numChildren = 1

# 查看任务状态
get /tasks/task-0000000000/status

```
