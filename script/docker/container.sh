#!/bin/bash

# container.sh run/start/stop/rm docker-name container-name service-port

source ./env.sh "$2" "$3" "$4"

PROCESSED=0

function usage {
echo "Usage : container.sh run/start/stop/restart/rm docker-name container-name service-port"
}

if [ ! -z "$DOCKER_NAME" ] && [ ! -z "$CONTAINER_NAME" ] && [ ! -z "$SERVICE_PORT" ]
then

# 컨테이너 생성
# container.sh run userid userport
if [ "$1" = "run" ]
then
docker run -v ${DOCKER_CERTS}:/opt/otpkey/certs --restart always -h $DOCKER_NAME -d --cap-add SYS_NICE -p ${SERVICE_PORT}:443 --name ${DOCKER_NAME}_${CONTAINER_NAME} $DOCKER_NAME
PROCESSED=1
fi

# 컨테이너 가동
# container.sh start userid
if [ "$1" = "start" ]
then
docker start ${DOCKER_NAME}_${CONTAINER_NAME}
PROCESSED=1
fi

# 컨테이너 중지
# container.sh stop userid
if [ "$1" = "stop" ]
then
docker stop ${DOCKER_NAME}_${CONTAINER_NAME}
PROCESSED=1
fi

# 컨테이너 재가동
# container.sh restart userid
if [ "$1" = "restart" ]
then
docker restart ${DOCKER_NAME}_${CONTAINER_NAME}
PROCESSED=1
fi

# 컨테이너 삭제
# container.sh rm userid
if [ "$1" = "rm" ]
then
docker rm ${DOCKER_NAME}_${CONTAINER_NAME}
PROCESSED=1
fi

fi


if [ $PROCESSED -eq 0 ]
then
usage
fi