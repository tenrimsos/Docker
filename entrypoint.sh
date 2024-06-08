#!/bin/sh
openrc

sh /etc/v2ray/config.sh
sh /etc/wireguard/config.sh
sh /etc/ipsec.d/config.sh
sh /etc/openvpn/install.sh

#Droobear
rc-service dropbear start
#Stunnel
/etc/init.d/stunnel restart
#Squid
/etc/init.d/squid restart
#Shadowsocks
rc-service ss-srv start
#Hystwria
service hysteria start
#v2ray
service nginx restart
service v2ray restart
#Wireguard
wg-quick up wg0
#IKEv2
service ipsec start
#OpenVPN
cd /etc/openvpn && openvpn --config /etc/openvpn/server.conf

#sed -i 's#sh /etc/v2ray/config.sh##g' /entrypoint.sh
#sed -i 's#sh /etc/wireguard/config.sh##g' /entrypoint.sh
#sed -i 's#sh /etc/openvpn/install.sh##g' /entrypoint.sh
#sed -i 's#sh /etc/ipsec.d/config.sh##g' /entrypoint.sh

ssh-keygen -A
exec /usr/sbin/sshd -D -e "$@"
