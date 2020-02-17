# protobuf基础语法
protobuf的全称为protocol buffers，是由google推出的序列化(IDL Interface Definition Language)的框架,
通过定义`.proto`文件结合编译器, 能够生成其他语言相关的代码。

1. 创建`.proto`后缀的文件
```proto
option go_package = "ssty.com/miniapp/proto/activity";

option java_multiple_files = false;
option java_outer_classname = "ActivityManagerServiceProto";
option java_package = "com.ssty.miniapp.proto.activity";

import "google/api/annotations.proto";
import "api/annotations.proto";
import "common.proto";
service RouteGuide {

}
```

2. 定义`rpc`方法
对于protobuf的rpc方法的定义，总共有四种形式

2.1 简单的rpc的调用, 通过stub(存根?)的方式调用服务端, 并且阻塞等待服务端返回信息.这种方式就像普通方法调用
```proto
rpc GetFeature(Point) returns (Feature) {}
```
2.2 `A server-side streaming RPC` where the client sends a request to the server and gets a stream to read a sequence of messages back. The client reads from the returned stream until there are no more messages. As you can see in our example, you specify a server-side streaming method by placing the stream keyword before the response type.
```proto
// Obtains the Features available within the given Rectangle.  Results are
// streamed rather than returned at once (e.g. in a response message with a
// repeated field), as the rectangle may cover a large area and contain a
// huge number of features.

rpc ListFeatures (Rectagle) returns (stream Feature) {}
```

2.3 `A client-side streaming RPC` where the client writes a sequence of messages and sends them to the server, again using a provided stream. Once the client has finished writing the messages, it waits for the server to read them all and return its response. You specify a client-side streaming method by placing the stream keyword before the request type.
```proto
// Accepts a stream of Points on a route being traversed, returning a
// RouteSummary when traversal is completed.

rpc RecordRoute (stream Point) returns (RouteSummary) {}
```

2.4 `A bidirectional(双向的) streaming RPC` where both sides send a sequence of messages using a read-write stream. The two streams operate independently, so clients and servers can read and write in whatever order they like: for example, the server could wait to receive all the client messages before writing its responses, or it could alternately read a message then write a message, or some other combination of reads and writes. The order of messages in each stream is preserved. You specify this type of method by placing the stream keyword before both the request and the response.

```proto
// Accepts a stream of RouteNotes sent while a route is being traversed,
// while receiving other RouteNotes (e.g. from other users).

rpc RouteChat (stream RouteNote) returns (stream RouteNote){}
```

3. 定义请求或者消息主体
消息就相当于一个POJO对象, 其中定义了包含的属性字段。如下可以看出, 每个属性都有顺序，都会按照顺序依次写入, 对于message而言，其中的属性的定义顺序按照`1`依次递增。
```proto
message Point {
  int32 latitude = 1;
  int32 longitude = 2;
}
```

4. 根据`.proto`文件生成对应的源码(proto编译器)
