# centos stream9 切换阿里源

> 由于阿里云的镜像地址随时都在变, 因此可以通过[centos-stream安装包下载_开源镜像站-阿里云](https://mirrors.aliyun.com/centos-stream/?spm=a2c6h.13651104.d-5239.1.702531dbzZ70Vn)进行访问，查看事实的镜像地址

## 备份镜像源

```shell
cp -a /etc/yum.repos.d /etc/yum.repos.d.backup
```

## 删除已有的repo配置

```shell
rm -f /etc/yum.repos.d/*.repo
```

## 配置新的repo文件

```shell
touch Centos-linux-BaseOS.repo
vi Centos-linux-BaseOS.repo
```

输入以下的配置内容:

```shell
[base]
name=CentOS-$stream - Base
baseurl=http://mirrors.aliyun.com/centos-stream/9-stream/BaseOS/x86_64/os/
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=BaseOS&infra=$infra
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[appstream]
name=CentOS-$stream - AppStream
baseurl=http://mirrors.aliyun.com/centos-stream/9-stream/AppStream/x86_64/os/
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=AppStream&infra=$infra
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
```

## 重新构建

```shell
yum clean all
yum makecache
```

以上就是centos stream9的更换阿里源的方法。
