#!/bin/bash

#/**
# * OTPKEY
# * certs.sh
# * https://otpkey.com/license
# * Copyright Ⓒ 2023 Certchip Corp. All rights reserved.
# */

CMD=$1
DOMAIN=$2
PROVIDER=$3
EMAIL=$4
FIREWALL=$5
TEST=$6
COPY=$7

function usage {
    echo "Usage : certs.sh new domain [-certbot your_email] [-firewall] [-test] [-copy/-symlink]"
    echo "Usage : certs.sh renew domain [-certbot] [-test] [-copy/-symlink]"
}

PROCESSED=0


if [ "$CMD" == "renew" ] && [ ! -z "$DOMAIN" ]
then
    if [ "$PROVIDER" == "-certbot" ]
    then
        if [ "$EMAIL" == "-test" ] || [ "$EMAIL" == "test" ] 
        then
            certbot renew --dry-run
            PROCESSED=1
        else
            certbot renew
            PROCESSED=1
        fi
    fi

    if [ "$EMAIL" == "-copy" ] || [ "$FIREWALL" == "-copy" ]                     
    then
        mkdir -p ./certs/${DOMAIN}
        rm -f ./certs/${DOMAIN}/cert.pem
        rm -f ./certs/${DOMAIN}/chain.pem
        rm -f ./certs/${DOMAIN}/fullchain.pem
        rm -f ./certs/${DOMAIN}/privkey.pem
        cp -f /etc/letsencrypt/live/${DOMAIN}/cert.pem ./certs/${DOMAIN}/.                                    
        cp -f /etc/letsencrypt/live/${DOMAIN}/chain.pem ./certs/${DOMAIN}/.                                   
        cp -f /etc/letsencrypt/live/${DOMAIN}/fullchain.pem ./certs/${DOMAIN}/.                               
        cp -f /etc/letsencrypt/live/${DOMAIN}/privkey.pem ./certs/${DOMAIN}/.                                 
        echo "Copied"
        PROCESSED=1
    fi

    if [ "$EMAIL" == "-symlink" ] || [ "$FIREWALL" == "-symlink" ]
    then
        mkdir -p ./certs/${DOMAIN}                                                                            
        rm -f ./certs/${DOMAIN}/cert.pem
        rm -f ./certs/${DOMAIN}/chain.pem
        rm -f ./certs/${DOMAIN}/fullchain.pem
        rm -f ./certs/${DOMAIN}/privkey.pem
        ln -sf /etc/letsencrypt/live/${DOMAIN}/cert.pem ./certs/${DOMAIN}/.                                   
        ln -sf /etc/letsencrypt/live/${DOMAIN}/chain.pem ./certs/${DOMAIN}/.                                  
        ln -sf /etc/letsencrypt/live/${DOMAIN}/fullchain.pem ./certs/${DOMAIN}/.                              
        ln -sf /etc/letsencrypt/live/${DOMAIN}/privkey.pem ./certs/${DOMAIN}/.                                
        echo "Made symbolic link"                                                                             
        PROCESSED=1
    fi

fi


if [ "$CMD" == "new" ] && [ ! -z "$DOMAIN" ] && [ "$PROVIDER" == "-certbot" ] && [ ! -z "$EMAIL" ]
then

    echo "DOMAIN: ${DOMAIN}"
    echo "EMAIL: ${EMAIL}"
    echo "OPTIONS: ${PROVIDER} ${FIREWALL} ${TEST}"

    if [ "$FIREWALL" == "-firewall" ]
    then
        firewall-cmd --permanent --zone=public --add-service=http
        firewall-cmd --permanent --zone=public --add-service=https
        firewall-cmd --reload
    fi

    if [ "$FIREWALL" == "-test" ] || [ "$TEST" == "-test" ]
    then
        certbot certonly --standalone --email ${EMAIL} -d ${DOMAIN} --dry-run
        PROCESSED=1
    else
        certbot certonly --standalone --email ${EMAIL} -d ${DOMAIN}
        PROCESSED=1
    fi

    if [ "$COPY" == "-copy" ] || [ "$FIREWALL" == "-copy" ] || [ "$TEST" == "-copy" ]
    then
        mkdir -p ./certs/${DOMAIN}
        rm -f ./certs/${DOMAIN}/cert.pem
        rm -f ./certs/${DOMAIN}/chain.pem
        rm -f ./certs/${DOMAIN}/fullchain.pem
        rm -f ./certs/${DOMAIN}/privkey.pem
        cp -f /etc/letsencrypt/live/${DOMAIN}/cert.pem ./certs/${DOMAIN}/.
        cp -f /etc/letsencrypt/live/${DOMAIN}/chain.pem ./certs/${DOMAIN}/.
        cp -f /etc/letsencrypt/live/${DOMAIN}/fullchain.pem ./certs/${DOMAIN}/.
        cp -f /etc/letsencrypt/live/${DOMAIN}/privkey.pem ./certs/${DOMAIN}/.
        echo "Copied"
        PROCESSED=1
    fi

    if [ "$COPY" == "-symlink" ] || [ "$FIREWALL" == "-symlink" ] || [ "$TEST" == "-symlink" ]
    then
        mkdir -p ./certs/${DOMAIN}
        rm -f ./certs/${DOMAIN}/cert.pem
        rm -f ./certs/${DOMAIN}/chain.pem
        rm -f ./certs/${DOMAIN}/fullchain.pem
        rm -f ./certs/${DOMAIN}/privkey.pem
        ln -sf /etc/letsencrypt/live/${DOMAIN}/cert.pem ./certs/${DOMAIN}/.
        ln -sf /etc/letsencrypt/live/${DOMAIN}/chain.pem ./certs/${DOMAIN}/.
        ln -sf /etc/letsencrypt/live/${DOMAIN}/fullchain.pem ./certs/${DOMAIN}/.
        ln -sf /etc/letsencrypt/live/${DOMAIN}/privkey.pem ./certs/${DOMAIN}/.
        echo "Made symbolic link"
        PROCESSED=1
    fi
fi

if [ $PROCESSED -eq 0 ]
then
    usage
fi