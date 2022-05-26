#!/bin/bash
export ProgName=`basename $0`
cd `dirname $0`
export CurrDir=`pwd`
cd - > /dev/null 2>&1

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/bin"

# 安装docker
yum install -y docker
systemctl enable docker && systemctl start docker
## 给history加上时间戳和用户名
sed -i -r "/export[[:space:]]+HISTTIMEFORMAT/d" /etc/profile
echo 'export HISTTIMEFORMAT="%F %T `whoami`  "' >> /etc/profile
## 启用开机自动启动
chmod +x /etc/rc.d/rc.local
systemctl enable rc-local.service
systemctl start rc-local.service
## ssh连接加速
sed -i -r -e "/^UseDNS/d" -e "/#UseDNS/a UseDNS no" /etc/ssh/sshd_config
## 允许root登录
#sed -ri 's/^/#/;s/sleep 10"\s+/&\n/' /root/.ssh/authorized_keys
systemctl reload sshd

## 设置最大打开文件数
ulimit -n 524288
sed -i "/soft nofile/d" /etc/security/limits.conf
sed -i "/hard nofile/d" /etc/security/limits.conf
cat >>/etc/security/limits.conf <<\EOF
root soft nofile 524288
root hard nofile 524288
* soft nofile 524288
* hard nofile 524288
EOF

## 数据盘分区格式化
disk="/dev/nvme1n1"
mkfs -t ext4  $disk
mkdir -p /data
sed -i "/\/data/d" /etc/fstab
cat >> /etc/fstab <<EOF
$(blkid |grep "$disk" |awk '{print $2}') /data        ext4   defaults,noatime,nofail  0 0
EOF
mount -a

## 设置系统时区为中国上海
timedatectl -V > /dev/null 2>&1
if [ $? -ne 127 ]; then
    timedatectl set-timezone  Asia/Shanghai
else
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
fi

## 安装node_exporter

## 安装consul-client


## 配置可以被jumpserver统一root管理用户连接
##待定
