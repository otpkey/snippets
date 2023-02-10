#/**
# * OTPKEY
# * Dockerfile
# * https://otpkey.com/license
# * Copyright Ⓒ 2023 Certchip Corp. All rights reserved.
# */

FROM centos:8
USER root

ARG DOMAIN
ARG PUSHURL

ENV HTTPPORT 80
ENV HTTPSPORT 443
ENV WASHTTPPORT 8080
ENV WASHTTPSPORT 8443
ENV REDISHOST 127.0.0.1
ENV REDISPORT 6379
ENV DBSHOST 127.0.0.1
ENV DBSUSER otpkey
ENV DBSPW asdfASDF1!
ENV DOMAINHOST 127.0.0.1

RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Linux-*
RUN sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-Linux-*

RUN rpm --import /etc/pki/rpm-gpg/RPM*

RUN dnf update -y libmodulemd
RUN dnf install -y epel-release --nogpgcheck
#RUN dnf update -y libmodulemd
#RUN dnf upgrade -y
RUN dnf install -y certbot --nogpgcheck


# RUN yum update -y
RUN yum install -y wget
RUN yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel --nogpgcheck
RUN yum install -y net-tools
RUN yum install -y nginx
#RUN yum install -y unzip


RUN rm -rf /opt/otpkey          
RUN useradd -m -d /opt/otpkey -U -s /bin/false otpkey

RUN rm -f apache-tomcat-8.5.84.tar.gz
RUN wget https://archive.apache.org/dist/tomcat/tomcat-8/v8.5.84/bin/apache-tomcat-8.5.84.tar.gz
RUN tar xzf apache-tomcat-8.5.84.tar.gz
RUN mv apache-tomcat-8.5.84/* /opt/otpkey/
RUN rm -rf apache-tomcat-8.5.84
RUN rm -f apache-tomcat-8.5.84.tar.gz

RUN rm -f libotpkey.so
RUN wget --no-cache https://github.com/otpkey/snippets/raw/main/dist/corelibs/linux-x86_64/libotpkey.so
RUN mv -f libotpkey.so /lib64/.

RUN rm -f OTPKeyCore.jar
RUN wget --no-cache https://github.com/otpkey/snippets/raw/main/dist/java/latest/OTPKeyCore.jar
RUN mv -f OTPKeyCore.jar /opt/otpkey/lib/.

RUN rm -f extjars.tar.gz
RUN rm -rf extjars
RUN wget --no-cache https://github.com/otpkey/snippets/raw/main/dist/java/extjars.tar.gz
RUN mkdir extjars
RUN tar -zxvf extjars.tar.gz -C ./extjars
RUN rm -f extjars.tar.gz
RUN mv -f ./extjars/extjars/*.jar /opt/otpkey/lib/.
RUN rm -rf extjars

RUN rm -rf /opt/otpkey/webapps/*

RUN rm -f OTPKeyADM.war
RUN wget --no-cache https://github.com/otpkey/snippets/raw/main/dist/java/latest/OTPKeyADM.war
RUN mv -f OTPKeyADM.war /opt/otpkey/webapps/.

RUN rm -f OTPKeyAPI.war
RUN wget --no-cache https://github.com/otpkey/snippets/raw/main/dist/java/latest/OTPKeyAPI.war
RUN mv -f OTPKeyAPI.war /opt/otpkey/webapps/.

RUN rm -f OTPKeySVR.war
RUN wget --no-cache https://github.com/otpkey/snippets/raw/main/dist/java/latest/OTPKeySVR.war
RUN mv -f OTPKeySVR.war /opt/otpkey/webapps/.

RUN rm -f snippet.server.xml
RUN wget --no-cache https://raw.githubusercontent.com/otpkey/snippets/main/snippet.server.xml
RUN sed -i "s/{CERTS}\//\/opt\/otpkey\/certs\/${DOMAIN}\//g" snippet.server.xml
RUN mv -f snippet.server.xml /opt/otpkey/conf/server.xml


RUN mkdir -p /opt/otpkey/html
RUN rm -f preparing.html
RUN wget --no-cache https://raw.githubusercontent.com/otpkey/snippets/main/dist/html/preparing.html
RUN mv -f preparing.html /opt/otpkey/html/preparing.html
RUN rm -f installing.html
RUN wget --no-cache https://raw.githubusercontent.com/otpkey/snippets/main/dist/html/installing.html
RUN mv -f installing.html /opt/otpkey/html/installing.html


ENV CERTSPATH /opt/otpkey/certs
RUN mkdir "${CERTSPATH}"
ENV CERTBOTSH "${CERTSPATH}/certbot.sh"

ENV CATALINAPROP /opt/otpkey/conf/catalina.properties
RUN echo "" >> ${CATALINAPROP}
RUN echo "# PROP Path" >> ${CATALINAPROP}
RUN echo "com.otpkey.propPath=${CATALINAPROP}" >> ${CATALINAPROP}
RUN echo "" >> ${CATALINAPROP}
RUN echo "# Address for SVR => Redis" >> ${CATALINAPROP}
RUN echo "com.otpkey.redisr=redis://OTPKEY_REDIS:${REDISPORT}" >> ${CATALINAPROP}
RUN echo "# Address for Client => SVR WebSocket" >> ${CATALINAPROP}
RUN echo "com.otpkey.webskt=wss://${DOMAIN}/OTPKeySVR/otpkey/wsock" >> ${CATALINAPROP}
RUN echo "# WebSocket Connection Delay Time (msec)" >> ${CATALINAPROP}
RUN echo "com.otpkey.wsdely=10" >> ${CATALINAPROP}
RUN echo "# Address for SVR => Push Server" >> ${CATALINAPROP}
RUN echo "com.otpkey.pusher=${PUSHURL}" >> ${CATALINAPROP}
RUN echo "# Address for API => SVR" >> ${CATALINAPROP}
RUN echo "com.otpkey.server=https://${DOMAIN}:${WASHTTPSPORT}/OTPKeySVR" >> ${CATALINAPROP}
RUN echo "# Address for Mobile App (Push and QRS) => API" >> ${CATALINAPROP}
RUN echo "com.otpkey.auther=https://${DOMAIN}/OTPKeyAPI/otpkey/otpkey.jsp?api=credential" >> ${CATALINAPROP}
RUN echo "" >> ${CATALINAPROP}
RUN echo "# Database" >> ${CATALINAPROP}
RUN echo "com.otpkey.jdbcManageable=false" >> ${CATALINAPROP}
RUN echo "com.otpkey.jdbcDriver=com.mysql.cj.jdbc.Driver" >> ${CATALINAPROP}
RUN echo "com.otpkey.jdbcUrl=jdbc:mysql://OTPKEY_DBS:3306/otpkey?useSSL=false&serverTimezone=Asia/Seoul&useUnicode=true&character_set_server=utf8" >> ${CATALINAPROP}
RUN echo "com.otpkey.jdbcUsername=${DBSUSER}" >> ${CATALINAPROP}
RUN echo "com.otpkey.jdbcPassword=${DBSPW}" >> ${CATALINAPROP}

RUN rm -f snippet.nginx.conf
RUN wget --no-cache https://raw.githubusercontent.com/otpkey/snippets/main/snippet.nginx.conf
RUN sed -i "s/{CERTS}\//\/opt\/otpkey\/certs\/${DOMAIN}\//g" snippet.nginx.conf
RUN sed -i "s/{DOMAIN}/${DOMAIN}/g" snippet.nginx.conf
RUN sed -i "s/{WASHTTPSPORT}/${WASHTTPSPORT}/g" snippet.nginx.conf
RUN sed -i 's/www-data/root/g' snippet.nginx.conf
RUN mv -f snippet.nginx.conf /etc/nginx/nginx.conf

RUN yum -y install redis
RUN yum -y install mysql-server

EXPOSE ${HTTPPORT} ${HTTPSPORT}

WORKDIR /opt/otpkey

RUN echo "user=root" >> /etc/my.cnf.d/mysql-server.cnf

RUN cat /etc/hosts > hosts
RUN echo "" >> hosts
RUN echo "${DOMAINHOST} ${DOMAIN}" >> hosts
RUN echo "${DBSHOST} OTPKEY_DBS" >> hosts
RUN echo "${REDISHOST} OTPKEY_REDIS" >> hosts

RUN echo "#!/bin/bash" > startup.sh
RUN echo "cp -f hosts /etc/hosts" >> startup.sh

RUN echo "/opt/otpkey/certs/${DOMAIN}/certbot.sh &" >> startup.sh
RUN echo "sleep 5" >> startup.sh
RUN echo "redis-server &" >> startup.sh
RUN echo "sleep 1" >> startup.sh

RUN echo "if [ -d '/opt/otpkey/db' ]; then" >> startup.sh
RUN echo "mysqld --basedir=/usr --datadir=/opt/otpkey/db --user=root &" >> startup.sh
RUN echo "sleep 5" >> startup.sh
RUN echo "touch db_is_exists" >> startup.sh
RUN echo "else" >> startup.sh
RUN echo "mkdir /opt/otpkey/db" >> startup.sh
RUN echo "mysqld --initialize-insecure --basedir=/usr --datadir=/opt/otpkey/db --user=root" >> startup.sh
RUN echo "mysqld --basedir=/usr --datadir=/opt/otpkey/db --user=root &" >> startup.sh
RUN echo "sleep 5" >> startup.sh
RUN echo "mysql -e \"CREATE DATABASE otpkey CHARACTER SET utf8 COLLATE utf8_general_ci;\"" >> startup.sh
RUN echo "mysql -e \"CREATE USER '${DBSUSER}'@'localhost' IDENTIFIED BY '${DBSPW}';\"" >> startup.sh
RUN echo "mysql -e \"GRANT ALL PRIVILEGES ON otpkey.* TO '${DBSUSER}'@'localhost';\"" >> startup.sh
RUN echo "mysql -e \"FLUSH PRIVILEGES;\"" >> startup.sh
RUN echo "touch db_is_initialized" >> startup.sh
RUN echo "fi" >> startup.sh

RUN echo "nginx" >> startup.sh
RUN echo "sleep 1" >> startup.sh

RUN echo "./bin/catalina.sh run" >> startup.sh

RUN chown -R otpkey:otpkey /opt/otpkey/

RUN chmod +x startup.sh
RUN chown otpkey:otpkey startup.sh

ENTRYPOINT ["./startup.sh"]
