#!/bin/bash

CMD=$1

ORGANISATION=$2
DOMAIN=$3
ADMIN_PASSWORD=$4
CONFIG_PASSWORD=$5
CRYPT=$6
COST=$7

if [ ! -z "${ADMIN_PASSWORD}" ] && [ -z "${CONFIG_PASSWORD}" ]
then
    CONFIG_PASSWORD=$ADMIN_PASSWORD
fi

if [ ! -z "${ADMIN_PASSWORD}" ] && [ "${CONFIG_PASSWORD}" == "-BC" ]
then
    COST=$CRYPT
    CRYPT=$CONFIG_PASSWORD
    CONFIG_PASSWORD=$ADMIN_PASSWORD
    if [ -z "$COST" ]
    then
        COST=5
    fi
fi

if [ ! -z "${ADMIN_PASSWORD}" ] && [ "${CONFIG_PASSWORD}" == "-MD5" ]
then
    CRYPT=$CONFIG_PASSWORD
    CONFIG_PASSWORD=$ADMIN_PASSWORD
fi

if [ ! -z "${ADMIN_PASSWORD}" ] && [ "${CONFIG_PASSWORD}" == "-SHA" ]
then
    CRYPT=$CONFIG_PASSWORD
    CONFIG_PASSWORD=$ADMIN_PASSWORD
fi

if [ ! -z "${ADMIN_PASSWORD}" ] && [ "${CONFIG_PASSWORD}" == "-DES" ]
then
    CRYPT=$CONFIG_PASSWORD
    CONFIG_PASSWORD=$ADMIN_PASSWORD
fi

if [ ! -z "${ADMIN_PASSWORD}" ] && [ "${CONFIG_PASSWORD}" == "-BF" ]
then
    CRYPT=$CONFIG_PASSWORD
    CONFIG_PASSWORD=$ADMIN_PASSWORD
fi


CWD="$( cd "$(dirname "$0")" ; pwd -P )"

VERSION="latest"
IMAGE_ID=$(docker images -q osixia/openldap:$VERSION)

function _usage {
    echo "Usage : ldap.sh install {ORGANISATION} {DOMAIN} {ADMIN_PASSWORD} [{CONFIG_PASSWORD}] [-BC/-BF/-MD5/-SHA/-DES [{COST}]]"
    echo ""
    echo "  -BC : Use BCrypt encryption for passwords. This is currently considered to be very secure."
    echo "  -BF : Use Blowfish-based crypt(3) encryption for passwords."
    echo " -MD5 : Use Apache's modified MD5 algorithm for passwords. Passwords encrypted with this algorithm are transportable to any platform (Windows, Unix, BeOS, et cetera) running Apache 1.3.9 or later."
    echo " -SHA : Use SHA encryption for passwords. Facilitates migration from/to Netscape servers using the LDAP Directory Interchange Format (LDIF)."
    echo " -DES : Use DES-based crypt(3) encryption for passwords."
    echo "{COST}: This value is only allowed in combination with -BC (BCrypt encryption). It sets the computing time used for the BCrypt algorithm (higher is more secure but slower, default: 5, valid: 4 to 31)."
    echo ""
    echo "Usage : ldap.sh uninstall/start/restart/stop"
}

function _get_image_id {
    IMAGE_ID=$(docker images -q osixia/openldap:$VERSION)
}
function _get_container_id {
    CONTAINER_ID=$(docker ps -aqf "name=ldap")
}

function _rm {
    _stop
    docker rm -f ldap
    rm -rf "${CWD}/init"
    rm -rf "${CWD}/environment"
}
function _pull {
    docker pull osixia/openldap:$VERSION
}
function _clean {
    rm -rf "${CWD}/init"
    rm -rf "${CWD}/environment"
}
HTPASSWD=0
function _check_htpasswd {
    if [ ! -z "$(command -v htpasswd)" ]
    then
        echo "htpasswd already installed"
        HTPASSWD=1
    else
        if [ -f /etc/redhat-release ]
        then
            yum -y install httpd-tools
            HTPASSWD=1
        else
            if [ -f /etc/lsb-release ]
            then
                apt -y install apache2-utils
                HTPASSWD=1
            else
                echo "error: required htpasswd install"
            fi    
        fi
    fi
}

SECONDVAL=""
function _secondVal {
    local num=0
    for i in "$@"
    do
        ((num=num+1))
        if [ $num -eq 2 ]
        then
            SECONDVAL="${i}"
        fi
    done
}

function _init {
    ENVIRONMENT="$CWD/environment"
    mkdir -p "${ENVIRONMENT}"
    CONFIG="$ENVIRONMENT/config"
    mkdir -p "${CONFIG}"
    STARTUP_YAML="$CONFIG/env.startup.yaml"

    rm -f snippet.ldap.startup.yaml
    wget --no-cache https://raw.githubusercontent.com/otpkey/snippets/main/snippet.ldap.startup.yaml
    mv -f snippet.ldap.startup.yaml "${STARTUP_YAML}"

    sed -i "" "s/{LDAP_ORGANISATION}/${ORGANISATION}/g" "${STARTUP_YAML}"
    sed -i "" "s/{LDAP_DOMAIN}/${DOMAIN}/g" "${STARTUP_YAML}"
    sed -i "" "s/{LDAP_ADMIN_PASSWORD}/${ADMIN_PASSWORD}/g" "${STARTUP_YAML}"
    sed -i "" "s/{LDAP_CONFIG_PASSWORD}/${CONFIG_PASSWORD}/g" "${STARTUP_YAML}"

    mkdir -p "${CWD}/init"
    INIT_LDIF="${CWD}/init.ldif"
    if [ -f "${INIT_LDIF}" ]
    then
        cp -f "${INIT_LDIF}" "${CWD}/init/."
    else
        rm -f snippet.ldap.init.ldif
        wget --no-cache https://raw.githubusercontent.com/otpkey/snippets/main/snippet.ldap.init.ldif
        mv -f snippet.ldap.init.ldif "${CWD}/init/init.ldif"
    fi

    BaseDN="dc=${DOMAIN//./,dc=}"
    sed -i "" "s/otpkey.com/${DOMAIN}/g" "${CWD}/init/init.ldif"
    sed -i "" "s/dc=otpkey,dc=com/${BaseDN}/g" "${CWD}/init/init.ldif"

    if [ "${CRYPT}" == "-BC" ] || [ "${CRYPT}" == "-BF" ] || [ "${CRYPT}" == "-MD5" ] || [ "${CRYPT}" == "-SHA" ] || [ "${CRYPT}" == "-DES" ]
    then
        _check_htpasswd
        if [ $HTPASSWD -eq 1 ]
        then
            echo "Process for hash or crypt with htpasswd command."
            LDIFECHOFILE="${CWD}/init/init.ldif.echo"
            rm -f "${LDIFECHOFILE}"
            touch "${LDIFECHOFILE}"
            USERPASSWORDTAG="userPassword:"
            while read line
            do
                if [[ $line == ${USERPASSWORDTAG}* ]]
                then
                    SECONDVAL=""
                    _secondVal ${line}
                    if [ ! -z "${SECONDVAL}" ]
                    then
                        local line2=""
                        
                        if [ "${CRYPT}" == "-BC" ]
                        then
                            line2=`htpasswd -bnBC ${COST} "" ${SECONDVAL} | tr -d ':\n' | sed 's/$2y/$2a/'`
                        fi

                        if [ "${CRYPT}" == "-BF" ]
                        then
                            line2=`htpasswd -bnl ${SECONDVAL} | tr -d ':\n'`
                        fi

                        if [ "${CRYPT}" == "-MD5" ]
                        then
                            line2=`htpasswd -bnm ${SECONDVAL} | tr -d ':\n'`
                        fi

                        if [ "${CRYPT}" == "-SHA" ]
                        then
                            line2=`htpasswd -bns ${SECONDVAL} | tr -d ':\n'`
                        fi

                        if [ "${CRYPT}" == "-DES" ]
                        then
                            line2=`htpasswd -bnd ${SECONDVAL} | tr -d ':\n'`
                        fi

                        if [ -z "${line2}" ]
                        then
                            echo "${line}" >> "${LDIFECHOFILE}"
                        else
                            echo "${USERPASSWORDTAG} ${line2}" >> "${LDIFECHOFILE}"
                        fi
                    else
                        echo "${line}" >> "${LDIFECHOFILE}"
                    fi
                else
                    echo "${line}" >> "${LDIFECHOFILE}"
                fi
            done < "${CWD}/init/init.ldif"

            mv -f "${LDIFECHOFILE}" "${CWD}/init/init.ldif"
        else
            _uninstall
            echo "Not found htpassed. Uninstalled and Exit."
            exit 0
        fi
    fi

    docker create --name ldap \
        -v "${CONFIG}":/container/environment/01-custom \
        -v "${CWD}/init":/container/service/slapd/assets/config/bootstrap/ldif/custom\
        -p 389:389 -p 636:636 \
        osixia/openldap:$VERSION --loglevel debug --copy-service
}
function _start {
    _get_image_id
    if [ ! -z $IMAGE_ID ]
    then
        _get_container_id
        if [ ! -z $CONTAINER_ID ]
        then
            echo "start : $CONTAINER_ID"
            docker start $CONTAINER_ID
        fi
    fi
}
function _stop {
    _get_image_id
    if [ ! -z $IMAGE_ID ]
    then
        _get_container_id
        if [ ! -z $CONTAINER_ID ]
        then
            echo "stop : $CONTAINER_ID"
            docker stop $CONTAINER_ID
        fi
    fi
}
function _restart {
    _get_image_id
    if [ ! -z $IMAGE_ID ]
    then
        _get_container_id
        if [ ! -z $CONTAINER_ID ]
        then
            echo "restart : $CONTAINER_ID"
            docker restart $CONTAINER_ID
        fi
    fi
}
function _uninstall {
    _get_image_id
    if [ ! -z $IMAGE_ID ]
    then
        _get_container_id
        if [ -z $CONTAINER_ID ]
        then
            docker rmi $IMAGE_ID
            rm -rf "${CWD}/init"
            rm -rf "${CWD}/environment"
            echo "Uninstalled"
        else
            _stop
            docker rm -f $CONTAINER_ID
            docker rmi $IMAGE_ID
            rm -rf "${CWD}/init"
            rm -rf "${CWD}/environment"
            echo "Uninstalled"
        fi
    else
        echo "Not installed"
    fi
}

PROCESSED=0

if [ "${CMD}" == "install" ] && [ ! -z "$ORGANISATION" ] && [ ! -z "$DOMAIN" ] && [ ! -z "$ADMIN_PASSWORD" ] && [ ! -z "$CONFIG_PASSWORD" ]
then
    echo "Install..."

    if [ -z $IMAGE_ID ]
    then
        # LDAP image not found..
        _pull
        _init
        _start
        sleep 3
        _clean;
        echo "Installed and Started"
    else    
        # LDAP image exists.
        _get_container_id
        if [ -z $CONTAINER_ID ]
        then
            # LDAP does not started.
            _init
            _start
            sleep 3
            _clean;
            echo "Initialized and Started"
        else
            # LDAP already started.
            _restart
            echo "Restarted"
        fi
    fi
    PROCESSED=1
fi

if [ "${CMD}" == "uninstall" ]
then
    echo "Uninstall..."
    _uninstall
    PROCESSED=1
fi

if [ "${CMD}" == "start" ]
then
    echo "Start..."
    _start
    echo "Started"
    PROCESSED=1
fi

if [ "${CMD}" == "restart" ]
then
    echo "Restart..."
    _restart
    echo "Restarted"
    PROCESSED=1
fi

if [ "${CMD}" == "stop" ]
then
    echo "Stop..."
    _stop
    echo "Stopped"
    PROCESSED=1
fi


if [ $PROCESSED -eq 0 ]
then
    _usage
fi