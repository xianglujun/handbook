# grpc相关jar包的依赖

## maven依赖
```xml
<dependency>
  <groupId>io.grpc</groupId>
  <artifactId>grpc-netty-shaded</artifactId>
  <version>1.17.1</version>
</dependency>
<dependency>
  <groupId>io.grpc</groupId>
  <artifactId>grpc-protobuf</artifactId>
  <version>1.17.1</version>
</dependency>
<dependency>
  <groupId>io.grpc</groupId>
  <artifactId>grpc-stub</artifactId>
  <version>1.17.1</version>
</dependency>
```

## gradle 依赖
```gradle
compile 'io.grpc:grpc-netty-shaded:1.17.1'
compile 'io.grpc:grpc-protobuf:1.17.1'
compile 'io.grpc:grpc-stub:1.17.1'
```

## android依赖
```gradle
compile 'io.grpc:grpc-okhttp:1.17.1'
compile 'io.grpc:grpc-protobuf-lite:1.17.1'
compile 'io.grpc:grpc-stub:1.17.1'
```
