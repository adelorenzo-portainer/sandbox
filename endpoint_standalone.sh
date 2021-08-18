#!/bin/ash

#Install Docker endpoint
docker exec -it standalone /sbin/ip a show eth0 | grep inet | awk '{ print $2 }' | sed 's/.\{3\}$//' > /tmp/.standalone_ip
standalone_ip=`cat /tmp/.standalone_ip`

while true
do
st_agent=`docker exec standalone /usr/local/bin/docker ps | grep portainer_agent`
if [ -z "$st_agent" ]
then
      echo -ne '⚡ Portainer Agent Not Running yet\r'
else
      break
fi
sleep 1
done

sleep 5
jwt=`http POST :9000/api/auth Username="portainer" Password="portainer1234" | jq '.jwt' | sed 's/^.//' | sed 's/.$//'`
http --form POST :9000/api/endpoints "Authorization: Bearer $jwt" Name="docker" URL="tcp://$standalone_ip:9001" EndpointCreationType=2  TLS="true" TLSSkipVerify="true" TLSSkipClientVerify="true"
rm /tmp/.standalone_ip

