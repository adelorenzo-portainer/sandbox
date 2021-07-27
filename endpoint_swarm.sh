#!/bin/ash

#Install Docker Swarm endpoint
docker exec -it swarm1 /sbin/ip a show eth0 | grep inet | awk '{ print $2 }' | sed 's/.\{3\}$//' > /root/.swarm_ip
swarm_ip=`cat .swarm_ip`


while true
do
sw_agent=`docker exec standalone /usr/local/bin/docker ps | grep portainer_agent`
if [ -z "$sw_agent" ]
then
      echo -ne '⚡ Portainer Agent Not Running yet\r'
else
      break
fi
sleep 1
done

sleep 5
jwt=`http POST :9000/api/auth Username="portainer" Password="portainer1234" | jq '.jwt' | sed 's/^.//' | sed 's/.$//'`
http --form POST :9000/api/endpoints "Authorization: Bearer $jwt" Name="docker swarm" URL="tcp://$swarm_ip:9001" EndpointCreationType=2  TLS="true" TLSSkipVerify="true" TLSSkipClientVerify="true"
rm /root/.swarm_ip

