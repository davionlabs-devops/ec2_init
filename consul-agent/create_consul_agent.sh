#!/bin/bash
export ProgName=`basename $0`
cd `dirname $0`
export CurrDir=`pwd`
cd - > /dev/null 2>&1

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/bin"

function Usage
{
cat << END
******************************************************************************
*
* Usage:
*    $ProgName  TAG 
*
*such as:
*    $ProgName gameplus-dev
******************************************************************************

END
        exit
}

[ "$#" -lt 1 ] && Usage
export TAG="$1"
sed -i -r "s/_TAG_/${TAG}/g"  $CurrDir/agent.json
mkdir -p /data/consul-agent01 /etc/consul-agent
\cp -p -r $CurrDir/agent.json /etc/consul-agent/
chmod -R 777 /data/consul-agent01 /etc/consul-agent

function GetDefaultInf
{
        local InfWithDefaultRouting=`route -n | grep "^0.0.0.0" | sort -n -k 5 | head -1 | sed -e "s/ /\n/g" | tail -1`
        #Get name of first interface with IP, make it complicated so that it is compatible with CentOS7
        [ ! "$InfWithDefaultRouting" ] && InfWithDefaultRouting=`ifconfig | awk 'BEGIN{IfDescLineCount=1} {if($0 == "") IfDescLineCount=0; if(IfDescLineCount<3) printf("%s", $0);else if(IfDescLineCount == 3) printf("\n"); IfDescLineCount++;}' | grep -ivE "docker|lo|veth"|grep -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | head -1 | awk '{print $1}' | sed -r -e "s/://g"`
        #Make it complicated so that it is compatible with CentOS7
        echo $InfWithDefaultRouting
}

function GetInfIP {
        [ "$#" -ne 1 ] && return 1
        local InfName="$1"
        local LocalIP=`ifconfig $InfName | grep -E "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | sed -r -e "s/[^0-9]*([0-9.]+) .*/\1/g"`
        echo $LocalIP
}

export Def_IP=$(GetInfIP $(GetDefaultInf))

docker -V >/dev/null 2>&1
if [ $? -eq 127 ] ;then
    yum -y install docker
    systemctl enable docker
    systemctl start docker
fi

docker run -d --name=consul-agent01 \
--restart always \
-p 8301:8301/tcp \
-p 8301:8301/udp \
-v /etc/consul-agent/:/consul/userconfig/ \
-v /data/consul-agent01:/data/consul0 \
-e 'CONSUL_LOCAL_CONFIG={"skip_leave_on_interrupt": true}'  \
consul:1.10.3 agent -advertise=$Def_IP  -config-file=/consul/userconfig/agent.json -data-dir /data/consul0  -node=$(hostname)
