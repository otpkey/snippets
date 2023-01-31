#!/bin/bash

CMD=$1

CWD="$( cd "$(dirname "$0")" ; pwd -P )"

VERSION="latest"
IMAGE_ID=$(docker images -q osixia/openldap:$VERSION)

function _usage {
    echo "Usage : ldap.sh install/uninstall"
}

function _rm {
    docker rm -f ldap
    rm -rf $CWD/init/init.ldif
    rm -rf $CWD/environment/config/env.startup.yaml
}
function _pull {
    docker pull osixia/openldap:$VERSION
}
function _init {
    cp $CWD/environment/env.startup.yaml $CWD/environment/config
    mkdir -p $CWD/init
    cp $CWD/environment/init.ldif $CWD/init
    docker create --name ldap \
        -v $CWD/environment/config:/container/environment/01-custom \
        -v $CWD/init:/container/service/slapd/assets/config/bootstrap/ldif/custom\
        -p 389:389 -p 636:636 \
        osixia/openldap:$VERSION --loglevel debug --copy-service
    docker start ldap
}
function _restart {
    _rm
    _init
}

PROCESSED=0

if [ "${CMD}" == "install" ]
then
    if [ -z $IMAGE_ID ]
    then
        # LDAP image not found..
        _pull
        _init
    else    
        # LDAP image exists.
        CONTAINER_ID=$(docker ps -aqf "name=ldap")
        if [ -z $CONTAINER_ID ]
        then
            # LDAP does not started.
            _init
        else
            # LDAP already started.
            _restart
        fi
    fi
    PROCESSED=1
fi

if [ "${CMD}" == "uninstall" ]
then
    if [ ! -z $IMAGE_ID ]
    then
        CONTAINER_ID=$(docker ps -aqf "name=ldap")
        if [ -z $CONTAINER_ID ]
        then
            docker rmi $IMAGE_ID
            rm -rf $CWD/init
            rm -rf $CWD/environment/config/env.startup.yaml
        else
            docker rm -f $CONTAINER_ID
            docker rmi $IMAGE_ID
            rm -rf $CWD/init
            rm -rf $CWD/environment/config/env.startup.yaml
        fi
    fi
    PROCESSED=1
fi

if [ $PROCESSED -eq 0 ]
then
    _usage
fi