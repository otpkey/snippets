#!/bin/bash

#/**
# * OTPKEY
# * install-centos.sh
# * https://otpkey.com/license
# * Copyright Ⓒ 2023 Certchip Corp. All rights reserved.
# */

DOMAIN=dev.otpkey.org
PUSHURL=https://push.otpkey.com/functions/api

HTTPPORT=80
HTTPSPORT=443
EWASHTTPPORT=8080
WASHTTPSPORT=8443

REDISHOST=127.0.0.1
REDISPORT=6379

DBSHOST=127.0.0.1
DBSUSER=otpkey
DBSPW=asdfASDF1!

DOMAINHOST=127.0.0.1
SSLCERTLIVE=/etc/letsencrypt/live

SERVICENAME=otpkey.service
SERVICEFILE=/usr/lib/systemd/system/${SERVICENAME}
INSTALLDIR=/opt/otpkey

# firewall
firewall-cmd --add-port=${HTTPPORT}/tcp --permanent
firewall-cmd --add-port=${HTTPSPORT}/tcp --permanent
firewall-cmd --reload

rm -rf ${INSTALLDIR}
mkdir -p ${INSTALLDIR}
useradd -m -d ${INSTALLDIR} -U -s /bin/false otpkey

yum install -y net-tools

#=============================================
# for CentOS 7
# --------------------------------------------
# for nginx
yum install -y yum-utils
rm -f snippet.nginx.repo
wget https://raw.githubusercontent.com/otpkey/snippets/main/snippet.nginx.repo
mv -f snippet.nginx.repo /etc/yum.repos.d/.
yum-config-manager --enable nginx-mainline
# for redis
yum install -y epel-release
yum update -y
#=============================================

yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel

yum remove -y nginx
yum install -y nginx

rm -f apache-tomcat-8.5.84.tar.gz
wget https://archive.apache.org/dist/tomcat/tomcat-8/v8.5.84/bin/apache-tomcat-8.5.84.tar.gz
tar xzf apache-tomcat-8.5.84.tar.gz
mv apache-tomcat-8.5.84/* ${INSTALLDIR}/
rm -rf apache-tomcat-8.5.84
rm -f apache-tomcat-8.5.84.tar.gz


rm -f libotpkey.so
wget --no-cache https://github.com/otpkey/snippets/raw/main/dist/corelibs/linux-x86_64/libotpkey.so
mv -f libotpkey.so /usr/lib/.

rm -f OTPKeyCore.jar
wget --no-cache https://github.com/otpkey/snippets/raw/main/dist/java/latest/OTPKeyCore.jar
mv -f OTPKeyCore.jar ${INSTALLDIR}/lib/.

rm -f extjars.tar.gz
rm -rf extjars
wget --no-cache https://github.com/otpkey/snippets/raw/main/dist/java/extjars.tar.gz
mkdir extjars
tar -zxvf extjars.tar.gz -C ./extjars
rm -f extjars.tar.gz
mv -f ./extjars/extjars/*.jar ${INSTALLDIR}/lib/.
rm -rf extjars

rm -rf ${INSTALLDIR}/webapps/*

rm -f OTPKeyADM.war
wget --no-cache https://github.com/otpkey/snippets/raw/main/dist/java/latest/OTPKeyADM.war
mv -f OTPKeyADM.war ${INSTALLDIR}/webapps/.

rm -f OTPKeyAPI.war
wget --no-cache https://github.com/otpkey/snippets/raw/main/dist/java/latest/OTPKeyAPI.war
mv -f OTPKeyAPI.war ${INSTALLDIR}/webapps/.

rm -f OTPKeySVR.war
wget --no-cache https://github.com/otpkey/snippets/raw/main/dist/java/latest/OTPKeySVR.war
mv -f OTPKeySVR.war ${INSTALLDIR}/webapps/.

rm -f snippet.server.xml
wget --no-cache https://raw.githubusercontent.com/otpkey/snippets/main/snippet.server.xml
sed -i "s/{CERTS}\//\/opt\/otpkey\/certs\/${DOMAIN}\//g" snippet.server.xml
mv -f snippet.server.xml ${INSTALLDIR}/conf/server.xml

mkdir -p ${INSTALLDIR}/html
rm -f preparing.html
wget --no-cache https://raw.githubusercontent.com/otpkey/snippets/main/dist/html/preparing.html
mv -f preparing.html ${INSTALLDIR}/html/preparing.html
rm -f installing.html
wget --no-cache https://raw.githubusercontent.com/otpkey/snippets/main/dist/html/installing.html
mv -f installing.html ${INSTALLDIR}/html/installing.html

chown -R root:root ${INSTALLDIR}


CATALINAPROP=${INSTALLDIR}/conf/catalina.properties
echo "" >> ${CATALINAPROP}
echo "# PROP Path" >> ${CATALINAPROP}
echo "com.otpkey.propPath=${CATALINAPROP}" >> ${CATALINAPROP}
echo "" >> ${CATALINAPROP}
echo "# Address for SVR => Redis" >> ${CATALINAPROP}
echo "com.otpkey.redisr=redis://OTPKEY_REDIS:${REDISPORT}" >> ${CATALINAPROP}
echo "# Address for Client => SVR WebSocket" >> ${CATALINAPROP}
echo "com.otpkey.webskt=wss://${DOMAIN}/OTPKeySVR/otpkey/wsock" >> ${CATALINAPROP}
echo "# WebSocket Connection Delay Time (msec)" >> ${CATALINAPROP}
echo "com.otpkey.wsdely=10" >> ${CATALINAPROP}
echo "# Address for SVR => Push Server" >> ${CATALINAPROP}
echo "com.otpkey.pusher=${PUSHURL}" >> ${CATALINAPROP}
echo "# Address for API => SVR" >> ${CATALINAPROP}
echo "com.otpkey.server=https://${DOMAIN}:${WASHTTPSPORT}/OTPKeySVR" >> ${CATALINAPROP}
echo "# Address for Mobile App (Push and QRS) => API" >> ${CATALINAPROP}
echo "com.otpkey.auther=https://${DOMAIN}/OTPKeyAPI/otpkey/otpkey.jsp?api=credential" >> ${CATALINAPROP}
echo "" >> ${CATALINAPROP}
echo "# Database" >> ${CATALINAPROP}
echo "com.otpkey.jdbcManageable=false" >> ${CATALINAPROP}
echo "com.otpkey.jdbcDriver=com.mysql.cj.jdbc.Driver" >> ${CATALINAPROP}
echo "com.otpkey.jdbcUrl=jdbc:mysql://OTPKEY_DBS:3306/otpkey?useSSL=false&serverTimezone=Asia/Seoul&useUnicode=true&character_set_server=utf8" >> ${CATALINAPROP}
echo "com.otpkey.jdbcUsername=${DBSUSER}" >> ${CATALINAPROP}
echo "com.otpkey.jdbcPassword=${DBSPW}" >> ${CATALINAPROP}

rm -f snippet.nginx.conf
wget --no-cache https://raw.githubusercontent.com/otpkey/snippets/main/snippet.nginx.conf
sed -i "s/{CERTS}\//\/opt\/otpkey\/certs\/${DOMAIN}\//g" snippet.nginx.conf
sed -i "s/{DOMAIN}/${DOMAIN}/g" snippet.nginx.conf
sed -i "s/{WASHTTPSPORT}/${WASHTTPSPORT}/g" snippet.nginx.conf
sed -i 's/www-data/root/g' snippet.nginx.conf
mv -f snippet.nginx.conf /etc/nginx/nginx.conf

yum -y install redis
yum -y install mariadb-server

sed -i "/${DOMAINHOST} ${DOMAIN}/d" /etc/hosts
sed -i "/OTPKEY_DBS/d" /etc/hosts
sed -i "/OTPKEY_REDIS/d" /etc/hosts

echo "" >> /etc/hosts
echo "${DOMAINHOST} ${DOMAIN}" >> /etc/hosts
echo "${DBSHOST} OTPKEY_DBS" >> /etc/hosts
echo "${REDISHOST} OTPKEY_REDIS" >> /etc/hosts

mkdir -p ${INSTALLDIR}/db

# for CentOS 7
systemctl start redis
systemctl enable redis
systemctl start mariadb
systemctl enable mariadb

#mysqld_safe --initialize-insecure --basedir=/usr --datadir=${INSTALLDIR}/db --user=root
#mysqld --basedir=/usr --datadir=${INSTALLDIR}/db --user=root &
#sleep 5

mysql -e "CREATE DATABASE otpkey CHARACTER SET utf8 COLLATE utf8_general_ci;"
mysql -e "CREATE USER '${DBSUSER}'@'localhost' IDENTIFIED BY '${DBSPW}';"
mysql -e "GRANT ALL PRIVILEGES ON otpkey.* TO '${DBSUSER}'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

mkdir -p ${INSTALLDIR}/certs/${DOMAIN}      
rm -f ${INSTALLDIR}/certs/${DOMAIN}/cert.pem
rm -f ${INSTALLDIR}/certs/${DOMAIN}/chain.pem
rm -f ${INSTALLDIR}/certs/${DOMAIN}/fullchain.pem
rm -f ${INSTALLDIR}/certs/${DOMAIN}/privkey.pem
ln -sf ${SSLCERTLIVE}/${DOMAIN}/cert.pem ${INSTALLDIR}/certs/${DOMAIN}/.
ln -sf ${SSLCERTLIVE}/${DOMAIN}/chain.pem ${INSTALLDIR}/certs/${DOMAIN}/.                                  
ln -sf ${SSLCERTLIVE}/${DOMAIN}/fullchain.pem ${INSTALLDIR}/certs/${DOMAIN}/.                              
ln -sf ${SSLCERTLIVE}/${DOMAIN}/privkey.pem ${INSTALLDIR}/certs/${DOMAIN}/.                                

sed -i '/StartLimitInterval/d' /usr/lib/systemd/system/nginx.service
sed -i '/StartLimitBurst/d' /usr/lib/systemd/system/nginx.service
sed -i '/Restart/d' /usr/lib/systemd/system/nginx.service
sed -i '/RestartSec/d' /usr/lib/systemd/system/nginx.service

sed -i'' -r -e "/After/a\StartLimitBurst=5" /usr/lib/systemd/system/nginx.service
sed -i'' -r -e "/After/a\StartLimitInterval=200" /usr/lib/systemd/system/nginx.service
sed -i'' -r -e "/PIDFile/a\RestartSec=30" /usr/lib/systemd/system/nginx.service
sed -i'' -r -e "/PIDFile/a\Restart=always" /usr/lib/systemd/system/nginx.service

# for CentOS 7
sed -i '/user=/d' /usr/lib/systemd/system/nginx.service
sed -i'' -r -e "/PIDFile/a\user=root" /usr/lib/systemd/system/nginx.service
semanage permissive -a httpd_t
#semanage permissive -d httpd_t


#rm -f /etc/nginx/sites-enabled/default
systemctl daemon-reload
systemctl stop nginx
systemctl start nginx
systemctl enable nginx


# for CentOS 8
semanage fcontext -a -t bin_t "${INSTALLDIR}/bin(/.*)?"
restorecon -r -v ${INSTALLDIR}/bin


echo "[Unit]" > ${SERVICEFILE}
echo "Description=otpkey tomcat" >> ${SERVICEFILE}
echo "After=network.target syslog.target" >> ${SERVICEFILE}

echo "[Service]" >> ${SERVICEFILE}
echo "Type=forking" >> ${SERVICEFILE}
echo "Environment=\"${INSTALLDIR}\"" >> ${SERVICEFILE}
echo "User=root" >> ${SERVICEFILE}
echo "Group=root" >> ${SERVICEFILE}
echo "ExecStart=${INSTALLDIR}/bin/startup.sh" >> ${SERVICEFILE}
echo "ExecStop=${INSTALLDIR}/bin/shutdown.sh" >> ${SERVICEFILE}

echo "[Install]" >> ${SERVICEFILE}
echo "WantedBy=multi-user.target" >> ${SERVICEFILE}

systemctl daemon-reload
systemctl stop ${SERVICENAME}
systemctl start ${SERVICENAME}
systemctl enable ${SERVICENAME}

echo "Finished"