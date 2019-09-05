# docker简介

## Docker 组件
Docker有四大核心组件:
- Docker客户端和服务器, 也称为Docker殷勤
- Docker 镜像
- Registry
- Docker容器

## Docker能做什么
- 加速本地开发和构建流程, 使其更加高效, 更加轻量化. 本地开发人员可以构建、运行并分享Docker容器. 容器可以在开发环境中构建, 然后轻松地提交到测试环境中, 并最终进入生产环境。
- 能够让独立服务或应用程序在不同的环境中, 得到相同的运行结果。 这点在面向服务的架构和重度依赖微型服务的部署中尤其实用。
- 用Docker创建隔离的环境来进行测试
- Docker可以让开发者先在本机上构建一个复杂的程序或框架来进行测试, 而不是一开始就在生产环境部署、测试
- 构建一个多用户的平台即服务(Paas)基础设施
- 为开发、测试提供一个轻量级的独立沙盒环境, 或者将独立的沙盒环境用于技术教学.
- 提供软件即服务(SaaS)应用程序
- 高性能, 超大规模宿主机部署


## Docker 图形化工具实现

### DockerUI
```SH
# 查找容器程序
docker search dockerui

# 获取docker容器
docker pull abh1nav/dockerui

# 执行docker程序
docker run -d --privileged --name dockerui -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock abh1nav/dockerui
```
