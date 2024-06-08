FROM alpine:latest
LABEL maintainer="Tenrimsos "

#Preconfigure
RUN apk --update
RUN apk add --no-cache openrc bash sudo
RUN openrc
RUN touch /run/openrc/softlevel

#Configure OpenSSH
RUN apk add --no-cache openssh
RUN echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config
RUN adduser -h /home/freehttp -s /bin/sh -D freehttp
RUN echo -n 'freehttp:Free.098' | chpasswd

#Configure Dropbear
RUN apk add --no-cache dropbear
RUN sed -i s/DROPBEAR_OPTS=/'DROPBEAR_OPTS="-p 444"'/g /etc/conf.d/dropbear
RUN openrc
RUN touch /run/openrc/softlevel

#Configure Stunnel
RUN apk add stunnel
RUN cp /etc/stunnel/stunnel.conf /etc/stunnel/stunnel.conf.bak
RUN wget -O /etc/stunnel/stunnel.conf https://raw.githubusercontent.com/tenrimsos/VPS2024pro/main/stunnel.conf
RUN sed -i s/443/143/g /etc/stunnel/stunnel.conf
RUN wget -O /etc/stunnel/stunnel.pem https://raw.githubusercontent.com/tenrimsos/VPS2024pro/main/stunnel.pem

#Configure Squid
RUN apk add squid apache2-utils
RUN cp /etc/squid/squid.conf /etc/squid/squid.conf.bak
RUN wget -O /etc/squid/squid.conf https://raw.githubusercontent.com/tenrimsos/VPS2024pro/main/squid.conf
RUN ip=$(wget -qO - icanhazip.com) && sed -i s/squidIP/$ip/g /etc/squid/squid.conf
RUN htpasswd -b -c /etc/squid/authusers premiumhttp Free.098

#Configure Shadowsocks
RUN apk --no-cache add --repository http://mirrors.cloud.tencent.com/alpine/edge/testing shadowsocks-libev
RUN wget -O /etc/ss-srv.json https://raw.githubusercontent.com/tenrimsos/Docker/main/ss-srv.json
RUN wget -O /etc/init.d/ss-srv https://raw.githubusercontent.com/tenrimsos/Docker/main/ss-srv
RUN chmod +x /etc/init.d/ss-srv

#Configure obfs
RUN apk add gcc autoconf make libtool automake zlib-dev openssl asciidoc xmlto libpcre32 libev-dev g++ linux-headers
RUN apk add git
RUN git clone https://github.com/shadowsocks/simple-obfs.git
RUN cd simple-obfs && git submodule update --init --recursive
RUN cd simple-obfs && ./autogen.sh && ./configure && make && make install
RUN wget -O /etc/ss-srv.json https://raw.githubusercontent.com/tenrimsos/Docker/main/ss-srv_obfs.json

#Configure Hysteria2
#ENV HY2_PASSWORD = "Free.098"
COPY hy2.sh /home/
RUN sh /home/hy2.sh

#Configure v2ray
RUN apk add v2ray
RUN mv /etc/v2ray/config.json /etc/v2ray/config.bak
RUN wget -O /etc/v2ray/config.json "https://raw.githubusercontent.com/tenrimsos/VPS2024pro/main/v2ray_config.json"
RUN apk add nginx
RUN wget -O /etc/nginx/http.d/v2ray.conf "https://raw.githubusercontent.com/tenrimsos/VPS2024pro/main/v2ray.conf"
RUN sudo sed -i s/example.com/svv2ray.shop/g /etc/nginx/http.d/v2ray.conf
RUN sudo nginx -t
RUN rc-update add nginx default
RUN /etc/init.d/nginx start
RUN sudo apk add certbot certbot-nginx
RUN mkdir /usr/share/nginx/html
COPY index.html /usr/share/nginx/html/
RUN mv /etc/nginx/http.d/default.conf /etc/nginx/http.d/default.bak
RUN mkdir /var/log/v2ray

#Configure Wireguard
RUN apk add wireguard-tools iptables
RUN sysctl net.ipv4.ip_forward
RUN mkdir /etc/wireguard/configs
RUN mkdir /etc/wireguard/keys
RUN mkdir /etc/wireguard/keys/server
RUN mkdir /etc/wireguard/tools
RUN mkdir /etc/wireguard/tools/configs
COPY tools/configs/peer.conf /etc/wireguard/tools/configs/peer.conf
COPY tools/configs/server.conf /etc/wireguard/tools/configs/server.conf
COPY config.sh /etc/wireguard/config.sh

#Configure OpenVPN
RUN apk add --no-cache openvpn
RUN wget -O /home/openvpn-install.sh https://raw.githubusercontent.com/captainwasabi/openvpn-install/master/openvpn-install.sh
RUN wget -O /etc/openvpn/ca.crt http://159.223.207.237:8000/ca.crt
RUN wget -O /etc/openvpn/ca.key http://159.223.207.237:8000/ca.key
RUN wget -O /etc/openvpn/server.crt http://159.223.207.237:8000/server.crt
RUN wget -O /etc/openvpn/server.key http://159.223.207.237:8000/server.key
RUN wget -O /etc/openvpn/tls-crypt.key http://159.223.207.237:8000/tls-crypt.key
RUN wget -O /etc/openvpn/server.init http://159.223.207.237:8000/server.init
RUN wget -O /etc/openvpn/crl.pem http://159.223.207.237:8000/crl.pem
RUN mkdir /var/log/openvpn

#Configure IPsec Ikev2 Strongswan
COPY strongswan.sh /home/
ENV VPN_IPSEC_PSK = "vpnipsecaea0085b2024"
ENV VPN_USER = "freehttp"
ENV VPN_PASSWORD = "Free.098"
RUN sh /home/strongswan.sh



ENTRYPOINT ["/entrypoint.sh"]

#Expose Ports
EXPOSE 22/TCP
EXPOSE 80/TCP
EXPOSE 143/TCP
EXPOSE 443/TCP
EXPOSE 444/TCP
EXPOSE 500/UDP
EXPOSE 1194/UDP
EXPOSE 4500/UDP
EXPOSE 8000/TCP
EXPOSE 8080/TCP
EXPOSE 8388
EXPOSE 9999/UDP
EXPOSE 10000/TCP
EXPOSE 41194/UDP
COPY entrypoint.sh /

COPY /v2ray/config.sh /etc/v2ray/
COPY /wireguard/config.sh /etc/wireguard/
COPY /ikev2/config.sh /etc/ipsec.d/
COPY /openvpn/install.sh /etc/openvpn/
