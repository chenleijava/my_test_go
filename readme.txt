1.编译golang protobufgen  ,拷贝到gopath ,/usr/local/go/bin
2.管理三方依赖库采用glide来管理,其中项目结构:
- $GOPATH/src/myProject (Your project)
  |
  |-- glide.yaml
  |
  |-- glide.lock
  |
  |-- main.go (Your main go code can live here)
  |
  |-- mySubpackage (You can create your own subpackages, too)
  |    |
  |    |-- foo.go
  |
  |-- vendor
  |     |-- github.com
  |          |
  |          |-- Masterminds
  |                |
  |                |-- ... etc.
  $GOPATH/pkg       //平台相关
  |
  $GOPATH/bin       //可执行文件



3. 配置$GOPATH

    GOPATH=/home/user/gocode

    /home/user/gocode/
        src/                       //源代码
            foo/
                bar/               (go code in package bar)
                    x.go
                quux/              (go code in package main)
                    y.go
        bin/
            quux                   (installed command)   //可执行文件
        pkg/                            //平台相关文件
            linux_amd64/
                foo/
                    bar.a          (installed package object)