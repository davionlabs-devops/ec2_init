#!/bin/bash
export ProgName=`basename $0`
cd `dirname $0`
export CurrDir=`pwd`
cd - > /dev/null 2>&1

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/bin"

mkdir -p /data/consul-server01 /etc/consul
\cp -p -r $CurrDir/server.json /etc/consul/
chmod -R 777 /data/consul-server01 /etc/consul

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
docker run -d --name=consul-server01 \
--restart always \
-v /etc/consul/:/consul/userconfig/ \
-v /data/consul-server01:/data/consul0 \
--network "host" \
-e 'CONSUL_LOCAL_CONFIG={"skip_leave_on_interrupt": true}'  \
consul:1.12.2 agent -server -bootstrap-expect=1 -bind=$Def_IP -config-file=/consul/userconfig/server.json -data-dir /data/consul0 -node=consul-server01
