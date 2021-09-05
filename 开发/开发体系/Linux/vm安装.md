### 安装

1. vm: VMware® Workstation 15 Pro

2. linux: centos 7

3. 网络配置: NAT 模式（可连网）(DHCP 设置ip租用时间)

4. `vi /etc/sysconfig/network-scripts/ifcfg-ens33`

   ONBOOT=no，改为ONBOOT=yes

   service network restart

5. yum -y install net-tools

   ifconfig

6. xshell 连接