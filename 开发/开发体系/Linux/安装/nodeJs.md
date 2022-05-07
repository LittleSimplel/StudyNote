1. 准备 node 安装包，可以进入[镜像站](https://npm.taobao.org/mirrors/node/) ，自行选择版本进行下载，这里下载的是 [node-v12.18.3-linux-x64.tar.gz](https://registry.npmmirror.com/binary.html?path=node/v12.18.3/)

2. 上传压缩包到服务器 /home/app/node

3. mkdir /usr/local/node

4. 解压：tar -zxvf node-v12.18.3-linux-x64.tar.gz -C /usr/local/node

5. 将 node 加入环境变量中，修改 vi /etc/profile 文件

   ```shell
   export NODE_HOME=/home/dyyg/install/node-v12.18.3-linux-x64
   export PATH=$NODE_HOME/bin:$PATH
   ```

   source /etc/profile

6. 查看版本：node -v

   npm version

