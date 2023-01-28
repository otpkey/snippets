DOMAIN=demo.otpkey.com
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
SERVICEFILE=/etc/systemd/system/${SERVICENAME}
INSTALLDIR=/opt/otpkey

apt install -y net-tools
apt install -y openjdk-8-jdk-headless openjdk-8-jre-headless
apt install -y nginx
useradd -m -d ${INSTALLDIR} -U -s /bin/false otpkey


rm -f apache-tomcat-8.5.84.tar.gz
wget https://archive.apache.org/dist/tomcat/tomcat-8/v8.5.84/bin/apache-tomcat-8.5.84.tar.gz
tar xzf apache-tomcat-8.5.84.tar.gz
mv apache-tomcat-8.5.84/* ${INSTALLDIR}/
rm -rf apache-tomcat-8.5.84
rm -f apache-tomcat-8.5.84.tar.gz


rm -f libotpkey.so
wget --no-cache https://github.com/otpkey/snippets/raw/main/dist/corelibs/linux-x86_64/libotpkey.so
mv -f libotpkey.so /lib64/.
ln -sf /lib64/libotpkey.so /usr/lib/.

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
sed -i "s/\/certs\//\/opt\/otpkey\/certs\/${DOMAIN}\//g" snippet.server.xml
mv -f snippet.server.xml ${INSTALLDIR}/conf/server.xml

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

apt -y install redis
apt -y install mariadb-server

echo "" >> /etc/hosts
echo "${DOMAINHOST} ${DOMAIN}" >> /etc/hosts
echo "${DBSHOST} OTPKEY_DBS" >> /etc/hosts
echo "${REDISHOST} OTPKEY_REDIS" >> /etc/hosts

mkdir -p ${INSTALLDIR}/db
#mysqld --initialize-insecure --basedir=/usr --datadir=${INSTALLDIR}/db --user=root
#mysqld --basedir=/usr --datadir=${INSTALLDIR}/db --user=root &
#sleep 5

mysql -e "CREATE DATABASE otpkey CHARACTER SET utf8 COLLATE utf8_general_ci;"
mysql -e "CREATE USER '${DBSUSER}'@'localhost' IDENTIFIED BY '${DBSPW}';"
mysql -e "GRANT ALL PRIVILEGES ON otpkey.* TO '${DBSUSER}'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# 여기까지하면 mysqld, redis-server 이 자동 실행되도록 등록된다.
# 이제부터 nginx, tomcat 실행 스크립트를 등록해야 한다.

mkdir -p ${INSTALLDIR}/certs/${DOMAIN}      
rm -f ${INSTALLDIR}/certs/${DOMAIN}/cert.pem
rm -f ${INSTALLDIR}/certs/${DOMAIN}/chain.pem
rm -f ${INSTALLDIR}/certs/${DOMAIN}/fullchain.pem
rm -f ${INSTALLDIR}/certs/${DOMAIN}/privkey.pem
ln -sf ${SSLCERTLIVE}/${DOMAIN}/cert.pem ${INSTALLDIR}/certs/${DOMAIN}/.
ln -sf ${SSLCERTLIVE}/${DOMAIN}/chain.pem ${INSTALLDIR}/certs/${DOMAIN}/.                                  
ln -sf ${SSLCERTLIVE}/${DOMAIN}/fullchain.pem ${INSTALLDIR}/certs/${DOMAIN}/.                              
ln -sf ${SSLCERTLIVE}/${DOMAIN}/privkey.pem ${INSTALLDIR}/certs/${DOMAIN}/.                                

systemctl restart nginx
systemctl enable nginx


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

