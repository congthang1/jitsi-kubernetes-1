#!/bin/bash
set -e
#export HOSTNAME="${domain_name}"
#export EMAIL="${email_address}"

export HOSTNAME=$HOSTNAME.wysemeet.cf
export EMAIL=ramalingamvarkala@gmail.com

echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" >> /etc/resolv.conf
# disable ipv6
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
# set hostname
hostnamectl set-hostname $HOSTNAME
echo -e "127.0.0.1 localhost $HOSTNAME" >> /etc/hosts
apt update

# install awscli
apt-get install awscli -y

# create route53 recordset
sed -i "s/dnsrecord/$HOSTNAME/g" /home/ubuntu/route53-record.json
sed -i "s/public-ip/$(curl http://checkip.amazonaws.com)/g" /home/ubuntu/route53-record.json

aws route53 change-resource-record-sets --hosted-zone-id Z016456523EJLDTKQHOK5 --change-batch file:///home/ubuntu/route53-record.json

# install Java
apt install -y openjdk-8-jre-headless
echo "JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")" | sudo tee -a /etc/profile
source /etc/profile
# install NGINX
apt install -y nginx
systemctl start nginx.service
systemctl enable nginx.service
# add Jitsi to sources
wget -qO - https://download.jitsi.org/jitsi-key.gpg.key | sudo apt-key add -
sh -c "echo 'deb https://download.jitsi.org stable/' > /etc/apt/sources.list.d/jitsi-stable.list"
apt update
echo -e "DefaultLimitNOFILE=65000\nDefaultLimitNPROC=65000\nDefaultTasksMax=65000" >> /etc/systemd/system.conf
systemctl daemon-reload
# Configure Jits install
debconf-set-selections <<< $(echo 'jitsi-videobridge jitsi-videobridge/jvb-hostname string '$HOSTNAME)
debconf-set-selections <<< 'jitsi-meet-web-config   jitsi-meet/cert-choice  select  "Generate a new self-signed certificate"';

# Debug
echo $EMAIL >> /debug.txt
echo $HOSTNAME >> /debug.txt
cat /etc/resolv.conf >> /debug.txt
whoami >> /debug.txt
cat /etc/hosts >> /debug.txt
# Install Jitsi
apt install -y jitsi-meet &>> /debug.txt
# letsencrypt
export EMAIL=ramalingamvarkala@gmail.com
echo $EMAIL | /usr/share/jitsi-meet/scripts/install-letsencrypt-cert.sh &>> /debug.txt

sed -i "s/hostname/$HOSTNAME/g" /home/ubuntu/wyse-meet/react/api/instances.json
cd /home/ubuntu/wyse-meet/ && make

sed  '14s/false/true/' /etc/prosody/conf.d/$HOSTNAME.cfg.lua

sed -i 's+/usr/share/jitsi-meet+/home/ubuntu/wyse-meet+g' /etc/nginx/sites-available/$HOSTNAME.conf
systemctl restart nginx.service prosody.service
