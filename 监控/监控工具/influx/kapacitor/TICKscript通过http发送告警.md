## 通过http的方式发送告警
```sh
batch
|query('SELECT count("class") AS "count_code" FROM "telegraf"."autogen"."bu_global_seq" WHERE time > now() - 1d')
.period(10s)
.every(10s)
|alert()
.crit(lambda: int("count_code") > 1)
.message('''{'msgType':'text', 'text':{'content':'trade TPS is: {{index .Fields "count_code"}}'}}''')
.post('https://oapi.dingtalk.com/robot/send?access_token=995eca5ac67f845e7b5850c15ed50777b68e90a3ad4e041eaf512308d7ef22ce')
.header('Content-Type', 'application/json')
.captureResponse()
.log('/opt/kapacitor/log/log.log')
```
