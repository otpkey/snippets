#!/bin/bash

CMD=$1

ORGANISATION=$2
DOMAIN=$3
ADMIN_PASSWORD=$4
CONFIG_PASSWORD=$5


if [ ! -z "${ADMIN_PASSWORD}" ] && [ -z "${CONFIG_PASSWORD}" ]
then
    CONFIG_PASSWORD=$ADMIN_PASSWORD
fi

CWD="$( cd "$(dirname "$0")" ; pwd -P )"

VERSION="latest"
IMAGE_ID=$(docker images -q osixia/openldap:$VERSION)

function _usage {
    echo "Usage : ldap.sh install {ORGANISATION} {DOMAIN} {ADMIN_PASSWORD} [CONFIG_PASSWORD]"
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
    rm -rf $CWD/init/init.ldif
    rm -rf $CWD/environment/config/env.startup.yaml
}
function _pull {
    docker pull osixia/openldap:$VERSION
}
function _init {
    STARTUP_YAML="$CWD/environment/config/env.startup.yaml"
    cp -f "${CWD}/environment/env.startup.yaml" "${STARTUP_YAML}"

    echo "${ORGANISATION}"
    echo "${STARTUP_YAML}"

    sed -i "" "s/{LDAP_ORGANISATION}/${ORGANISATION}/g" "${STARTUP_YAML}"
    sed -i "" "s/{LDAP_DOMAIN}/${DOMAIN}/g" "${STARTUP_YAML}"
    sed -i "" "s/{LDAP_ADMIN_PASSWORD}/${ADMIN_PASSWORD}/g" "${STARTUP_YAML}"
    sed -i "" "s/{LDAP_CONFIG_PASSWORD}/${CONFIG_PASSWORD}/g" "${STARTUP_YAML}"

    mkdir -p $CWD/init
    cp -f $CWD/environment/init.ldif $CWD/init

    docker create --name ldap \
        -v $CWD/environment/config:/container/environment/01-custom \
        -v $CWD/init:/container/service/slapd/assets/config/bootstrap/ldif/custom\
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
        echo "Installed and Started"
    else    
        # LDAP image exists.
        _get_container_id
        if [ -z $CONTAINER_ID ]
        then
            # LDAP does not started.
            _init
            _start
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

    if [ ! -z $IMAGE_ID ]
    then
        _get_container_id
        if [ -z $CONTAINER_ID ]
        then
            docker rmi $IMAGE_ID
            rm -rf $CWD/init
            rm -rf $CWD/environment/config/env.startup.yaml
            echo "Uninstalled"
        else
            _stop
            docker rm -f $CONTAINER_ID
            docker rmi $IMAGE_ID
            rm -rf $CWD/init
            rm -rf $CWD/environment/config/env.startup.yaml
            echo "Uninstalled"
        fi
    else
        echo "Not installed"
    fi
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