#!/bin/bash

#/**
# * OTPKEY
# * env.sh
# * https://otpkey.com/license
# * Copyright Ⓒ 2023 Certchip Corp. All rights reserved.
# */

export DOCKER_NAME=$1
export DOCKER_DOMAIN=$2
export DOCKER_PUSHURL=https://push.otpkey.com/functions/api
export DOCKER_CERTS=${PWD}/certs
export DOCKER_CERTBOT=$3
export DOCKER_EMAIL=$4

export CONTAINER_NAME=$2
export SERVICE_PORT=$3