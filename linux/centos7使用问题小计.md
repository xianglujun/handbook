1. `yum install -y gcc`报错解决方案
```sh
错误：软件包：glibc-2.17-196.el7.i686 (yum.repo)
          需要：glibc-common = 2.17-196.el7
          已安装: glibc-common-2.17-222.el7.x86_64 (@base)
              glibc-common = 2.17-222.el7
          可用: glibc-common-2.17-196.el7.x86_64 (yum.repo)
              glibc-common = 2.17-196.el7
错误：软件包：gcc-4.8.5-16.el7.x86_64 (yum.repo)
          需要：cpp = 4.8.5-16.el7
          已安装: cpp-4.8.5-28.el7_5.1.x86_64 (@updates)
              cpp = 4.8.2-16.el7_5
              cpp = 4.8.5-28.el7_5.1
          可用: cpp-4.8.5-16.el7.x86_64 (yum.repo)
              cpp = 4.8.5-16.el7
              cpp = 4.8.2-16.
```

> yum distro-sync
