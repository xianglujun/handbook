# .proto文件的gradle编译方式
```json
apply plugin: 'com.google.protobuf'

buildscript {
  repositories {
    mavenCentral()
  }
  dependencies {
    classpath 'com.google.protobuf:protobuf-gradle-plugin:0.8.5'
  }
}

protobuf {
  protoc {
    artifact = "com.google.protobuf:protoc:3.5.1-1"
  }
  plugins {
    grpc {
      artifact = 'io.grpc:protoc-gen-grpc-java:1.17.1'
    }
  }
  generateProtoTasks {
    all()*.plugins {
      grpc {}
    }
  }
}
```
