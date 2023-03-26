# yarn使用教程

## 1. 安装命令

```shell
npm install -g yarn
```

## 2. 对比npm

- 速度超快：yarn缓存了每个下载过的包，所以在次使用时无需重复下载。同时利用并行下载以最大化资源利用率，因此安装速度更快

- 超级安全：在执行代码前，Yarn会通过算法校验每个安装包得完整性

## 3.  基本使用命令

```shell
# 开始新项目
yarn init

# 添加依赖包
yarn add [package]
yarn add [package]@[version]
yarn add [package] --dev

# 升级依赖包
yarn upgrade [package]@[version]

#移除依赖包
yarn remove [package]
```


