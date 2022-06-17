#!/bin/bash
export ProgName=`basename $0`
cd `dirname $0`
export CurrDir=`pwd`
cd - > /dev/null 2>&1

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/bin"

pkill node_exporter
rm -rf /usr/local/node_exporter
if [ $(arch) == "x86_64" ];then
  tar zxf $CurrDir/node_exporter-1.3.1.linux-amd64.tar.gz
  mv node_exporter-1.3.1.linux-amd64 /usr/local/node_exporter
elif [ $(arch) == "aarch64" ];then
  tar zxf $CurrDir/node_exporter-1.3.1.linux-arm64.tar.gz
  mv node_exporter-1.3.1.linux-arm64 /usr/local/node_exporter
fi

cat  >/usr/lib/systemd/system/node_exporter.service <<\EOF
[Unit]
Description=https://prometheus.io

[Service]
Restart=on-failure
ExecStart=/usr/local/node_exporter/node_exporter --collector.systemd --collector.systemd.unit-whitelist=(docker|kubelet|kube-proxy|flanneld).service

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable node_exporter
systemctl restart node_exporter
