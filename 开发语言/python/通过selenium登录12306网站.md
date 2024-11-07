# 通过selenium登录12306网站

```python
# 自动化实现12306登录
from selenium.webdriver import Chrome
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.wait import WebDriverWait

index_url = "https://www.12306.cn/index/index.html"
opts = Options()
opts.add_experimental_option("detach", True)
br = Chrome()
br.get(index_url)
# 等待界面加载完成
wait = WebDriverWait(br, 5, poll_frequency=.2)
login_btn_x = '//*[@id="J-btn-login"]'
# 等待标签的出现
wait.until(lambda d: d.find_element(By.XPATH, login_btn_x).is_displayed())
l_btn = br.find_element(By.XPATH, login_btn_x)
if l_btn is None:
    print("当前界面已登录，不需要再次登录")
    exit(3)

# 找到了按钮，则点击按钮
l_btn.click()

wait = WebDriverWait(br, 5, poll_frequency=.2)
account_btn = '//*[@id="toolbar_Div"]/div[2]/div[2]/ul/li[1]/a'
wait.until(lambda d: d.find_element(By.XPATH, account_btn).is_displayed())

# 输入账号和密码
br.find_element(By.XPATH, '//*[@id="J-userName"]').send_keys("xlj18782983705")
br.find_element(By.XPATH, '//*[@id="J-password"]').send_keys("xianglj19911212")
br.find_element(By.XPATH, '//*[@id="J-login"]').click()

wait = WebDriverWait(br, 2, poll_frequency=.2)
wait.until(lambda d: d.find_element(By.XPATH, '//*[@id="id_card"]').is_displayed())

br.find_element(By.XPATH, '//*[@id="id_card"]').send_keys("0693")
send_code_btn = br.find_element(By.XPATH, '//*[@id="verification_code"]')
content = send_code_btn.text

sms_code = None
if content in ["获取验证码", "重新获取"]:
    print("获取验证码成功!")
    send_code_btn.click()
    sms_code = input("请输入你收到的验证码: ")

if not sms_code:
    print("获取验证码失败!")
    exit(10)

br.find_element(By.XPATH, '//*[@id="code"]').send_keys(sms_code)
# 执行登录操作
br.find_element(By.XPATH, '//*[@id="sureClick"]').click()
print("登录完成!")

```
