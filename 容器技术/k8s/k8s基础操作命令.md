# k8s基础操作命令

```sh
# 更新deployment的镜像
kubectl set image deployments/kubernetes-bootcamp kubernetes-bootcamp=jocatalin/kubernetes-bootcamp:v2

# 查看镜像更新状态
kubectl rollout status deployments/kubernetes-bootcamp

# 回滚之前的更新操作
kubectl rollout undo deployments/kubernetes-bootcamp
```

