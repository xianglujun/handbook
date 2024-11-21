# 使用ZooKeeper管理rmi远程请求端地址

这里就不多做介绍，直接上代码

## Service

```java
package zookeeper.test.rmi.service;

import java.rmi.Remote;
import java.rmi.RemoteException;

public interface HelloService extends Remote {

    /**
     * 在顶级rmi方法时，必须要抛出RemoteException
     *
     * @param name
     * @throws RemoteException
     */
    void sayHello(String name) throws RemoteException;
}

```

```java
package zookeeper.test.rmi.service.impl;


import zookeeper.test.rmi.service.HelloService;

import java.rmi.RemoteException;
import java.rmi.server.UnicastRemoteObject;

public class HelloServiceImpl extends UnicastRemoteObject implements HelloService {

    public HelloServiceImpl() throws RemoteException {
    }

    @Override
    public void sayHello(String name) throws RemoteException {
        System.out.println(Thread.currentThread().getName() + ", name: " + name);
    }
}

```

## ZooKeeper管理工厂类

```shell
package zookeeper.test;

import org.apache.zookeeper.WatchedEvent;
import org.apache.zookeeper.Watcher;
import org.apache.zookeeper.ZooKeeper;

import java.io.IOException;

public class ZookeeperFactory {

    static {
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            System.out.println("执行钩子。。。");
            ZookeeperFactory.close();
        }));
    }

    private static String servers = "192.168.56.102:2181,192.168.56.103:2181,192.168.56.104:2181";
    private volatile static ZooKeeper zooKeeper;
    private static final Object MUTEX = new Object();
    private volatile static boolean isClosed = true;

    private ZookeeperFactory() {
    }

    public static ZooKeeper getInstance() {
        if (zooKeeper ==  null) {
            synchronized (MUTEX) {
                if (zooKeeper == null || isClosed) {
                    try {
                        zooKeeper = new ZooKeeper(servers, 3000, new Watcher() {
                            @Override
                            public void process(WatchedEvent event) {
                                System.out.println("Receive watched event: " + event);
                            }
                        });
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
            }
        }
        return zooKeeper;
    }

    public static void close() {
        synchronized (MUTEX) {
            if (zooKeeper != null) {
                try {
                    zooKeeper.close();
                } catch (InterruptedException e) {
                    throw new RuntimeException(e);
                }
            }
            isClosed = true;
        }
    }
}

```

> 这里只是使用了一个单例，并且在jvm退出的时候能够关闭ZooKeeper的Session，其他的没有什么用处。

## RMI Server端配置

```java
package zookeeper.test.rmi;

import org.apache.zookeeper.CreateMode;
import org.apache.zookeeper.KeeperException;
import org.apache.zookeeper.ZooDefs;
import org.apache.zookeeper.ZooKeeper;
import zookeeper.test.ZookeeperFactory;
import zookeeper.test.rmi.service.HelloService;
import zookeeper.test.rmi.service.impl.HelloServiceImpl;

import java.net.*;
import java.rmi.Naming;
import java.rmi.RemoteException;
import java.rmi.registry.LocateRegistry;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.List;

public class RMIServer {
    
    public static void main(String[] args) throws SocketException, RemoteException, MalformedURLException, InterruptedException, KeeperException {
        int port = 9093;

        String path = "/rmiservers/provider";

        Enumeration<NetworkInterface> networkInterfaces = NetworkInterface.getNetworkInterfaces();
        List<String> supportIps = new ArrayList<>();
        while (networkInterfaces.hasMoreElements()) {
            NetworkInterface networkInterface = networkInterfaces.nextElement();
            // 过滤没有启用或者回环地址
            if (networkInterface.isLoopback() || !networkInterface.isUp()) {
                continue;
            }

            Enumeration<InetAddress> inetAddresses = networkInterface.getInetAddresses();
            while (inetAddresses.hasMoreElements()) {
                InetAddress inetAddress = inetAddresses.nextElement();
                if (inetAddress.isLoopbackAddress()
                        || inetAddress.isLinkLocalAddress()
                        || inetAddress.isMulticastAddress()
                        || inetAddress instanceof Inet6Address) {
                    System.out.println("------" + inetAddress.getHostAddress());
                    continue;
                }

                String hostAddress = inetAddress.getHostAddress();
                System.out.println("ip: " + hostAddress);
                supportIps.add(hostAddress);
            }
        }

        String urlFormat = "rmi://%s:%d/hello";
        LocateRegistry.createRegistry(port);
        HelloService helloService = new HelloServiceImpl();

        ZooKeeper zooKeeper = ZookeeperFactory.getInstance();
        for (String ip : supportIps) {
            String url = String.format(urlFormat, ip, port);
            Naming.rebind(url, helloService);

            zooKeeper.create(path, url.getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.EPHEMERAL_SEQUENTIAL);
        }


    }
}

```

> 这里注册的ip地址是读取的当前主机的网卡列表信息，并过滤掉不需要使用的，然后通过RMI接口注册，并将注册的信息存储到ZooKeeper, 这里主要是采用了有序临时节点，这样当服务退出的时候，就能够删除服务节点

## 客户端实现

客户端主要流程就是从ZooKeeper获取服务列表，并从中选取一个调用。然后监听znode事件，并及时的更新服务列表的集合。

```java
package zookeeper.test.rmi;

import org.apache.zookeeper.KeeperException;
import org.apache.zookeeper.Watcher;
import org.apache.zookeeper.ZooKeeper;
import zookeeper.test.ZookeeperFactory;
import zookeeper.test.rmi.service.HelloService;

import java.net.MalformedURLException;
import java.rmi.Naming;
import java.rmi.NotBoundException;
import java.rmi.RemoteException;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

public class RMIClient {
    public static void main(String[] args) throws InterruptedException, KeeperException, MalformedURLException, NotBoundException, RemoteException {
        System.out.println("Client start...");
        ZooKeeper zooKeeper = ZookeeperFactory.getInstance();
        String path = "/rmiservers";

        List<String> children = new ArrayList<>();
        getGetChildren(zooKeeper, path, children);

        if (children.isEmpty()) {
            System.out.println("没有找到注册的provider服务列表");
            return;
        }

        int length = children.size();
        int index = new Random().nextInt(length);

        String subNode = children.get(index);

        byte[] bytes = zooKeeper.getData(path + "/" + subNode, false, null);
        String url = new String(bytes);

        HelloService helloService = (HelloService) Naming.lookup(url);
        helloService.sayHello("你好呀，服务端");

        Thread.sleep(Integer.MAX_VALUE);
    }

    private static List<String> getGetChildren(ZooKeeper zooKeeper, String path, List<String> children) throws InterruptedException, KeeperException {

        Watcher watcher = event -> {
            System.out.println("接收到事件信息");
            if (event.getState() == Watcher.Event.KeeperState.SyncConnected && event.getType() == Watcher.Event.EventType.NodeChildrenChanged) {
                try {
                    getGetChildren(zooKeeper, path, children);
                } catch (InterruptedException e) {
                    throw new RuntimeException(e);
                } catch (KeeperException e) {
                    throw new RuntimeException(e);
                }
            }
        };

        children.clear();
        List<String> subChildren = zooKeeper.getChildren(path, watcher, null);
        children.addAll(subChildren);

        System.out.println("当前结果集为: " + children.isEmpty());
        return children;
    }
}

```
