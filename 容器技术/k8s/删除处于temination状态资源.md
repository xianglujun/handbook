# 删除一直处于terminating状态的ns资源信息

```shell
# 1. 将资源信息到处为json
kubectl get ns <ns-name> -o json > tmp.json

# 2. 修改json文件，删除finalizers的内容

# 3. 暴露本机服务信息
kubectl proxy

# 4. 将修改后的json传入到服务器
curl -k -H "Content-Type:  application/json" -X PUT --data-binary @tmp.json  http://127.0.0.1:8001/api/v1/namespaces/<ns-name>/finalize
```