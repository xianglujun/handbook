## kapacitor docker操作

### 通过tick方式启动kapacaitor
```sh
docker run --name kapa -d --net host -v /opt/kapacitor:/opt/kapacitor -v /etc/kapacitor:/etc/kapacitor kapacitor
```


### 执行`tick`任务
```sh
kapacitor define cpu_alert -tick tf.tick
```
如果当前`define`的任务正在运行, 则会自动重启该任务, 如果不想重启, 则使用`-no-reload`

```note
NOTE: kapacitor 是一个客户端程序, 必须通过启动`kapacitor server`的方式然后才能够直接链接,
因此在docker容器下, 必须通过`docker exec -it imageName bash`进入容器内部, 然后执行
对应的`.tick`文件
```


### 查看`kapacitor` 任务列表
```sh
kapacitor list tasks
```


### 查看任务的详细信息
```sh
kapacitor show cpu_alert
```

### 启用任务, 并获取实时的数据
```sh
kapacitor enable cpu_alert
```

### 通过命令行的方式制定`dbrp`
```sh
kapacitor define cpu_alert -tick tf.tick -dbrp "telegraf"."autogen"."bu_trade"
```

### 定义一个`template task`
```sh
kapacitor define-template generic_mean_alert -tick path/to/template_script.tick
```

### 查看`template task`详情
```sh
kapacitor show-template generic_mean_alert
```

### 通过模板方式创建任务
```sh
kapacitor define cpu_alert -template generic_mean_alert -vars cpu_vars.json -dbrp telegraf.autogen
```

### 通过配置文件进行启动`template task`
```json
{
  "template-id": "generic_mean_alert",
  "dbrps": [{"db": "telegraf", "rp": "autogen"}],
  "vars": {
    "measurement": {"type" : "string", "value" : "mem" },
    "groups": {"type": "list", "value": [{"type":"star", "value":"*"}]},
    "field": {"type" : "string", "value" : "used_percent" },
    "warn": {"type" : "lambda", "value" : "\"mean\" > 80.0" },
    "crit": {"type" : "lambda", "value" : "\"mean\" > 90.0" },
    "window": {"type" : "duration", "value" : "10m" },
    "slack_channel": {"type" : "string", "value" : "#alerts_testing" }
  }
}
```
```sh
kapacitor define mem_alert -file mem_template_task.json
```

### 任务记录过去的一段时间数据用于测试
```sh
kapacitor record batch -task batch_cpu_alert -past 20m
```

### 加载`stream`数据
```sh
kapacitor record stream -task cpu_alert -duration 60s
```

### 列出加载的记录信息列表
```sh
kapacitor list recordings $rid
```

### 通过`recording`加载数据
```sh
kapacitor replay -recording $rid -task TaskName
```

### 采用recording数据进行数据重试
```sh
kapacitor replay -recording 00351625-a6ce-4739-bae0-3554d7580b3d -task tps

kapacitor replay -recording 4012860f-5a04-4acf-b3a2-f6eedb89492f -task ext_msg_center_elapse
```
