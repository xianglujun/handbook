# grpc底层实现三个重要的概念
在高级特性中, 在类库中包含了三个明显的层面： Stub, Channel, Transport


## Stub
> The Stub layer is what is exposed to most developers and provides type-safe bindings to whatever datamodel/IDL/interface you are adapting. gRPC comes with a plugin to the protocol-buffers compiler that generates Stub interfaces out of .proto files, but bindings to other datamodel/IDL are easy and encouraged.

该层面主要表述了, Stub是暴露给开发人员的数据模型, 接口语言定义, 以及接口信息。并且是伴随着protocol-buffers的编译器自动根据`.proto`文件产生源码。


## Channel
> The Channel layer is an abstraction over Transport handling that is suitable for interception/decoration and exposes more behavior to the application than the Stub layer. It is intended to be easy for application frameworks to use this layer to address cross-cutting concerns such as logging, monitoring, auth, etc.

Channel层抓哟是对传输层的抽象, 主要用来拦截/装饰比`Stub`提供了更多的操作行为。高层主要倾向于能够让应用框架更好的使用，例如对于横切的需要，例如: 日志，监控, 鉴权等。

## Transport

> The Transport layer does the heavy lifting of putting and taking bytes off the wire. The interfaces to it are abstract just enough to allow plugging in of different implementations. Note the transport layer API is considered internal to gRPC and has weaker API guarantees than the core API under package `io.grpc`.

> gRPC comes with three Transport implementations:

> The Netty-based transport is the main transport implementation based on Netty. It is for both the client and the server.
The OkHttp-based transport is a lightweight transport based on OkHttp. It is mainly for use on Android and is for client only.
The in-process transport is for when a server is in the same process as the client. It is useful for testing, while also being safe for production use.

传输层主要是用来对数据的传输和接收的工作。
