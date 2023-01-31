#!/bin/bash

# image.sh install/uninstall/build/make/run/start/stop/rm/bash/prun docker-name domain [-certbot your_email]

source ./env.sh "$2" "$3" "$4" "$5"

function usage {
    echo "Usage : image.sh install/uninstall/build/make/run/start/stop/restart/rm/bash/prun docker-name domain [-certbot your_email]"
}

function certbot {
    CERTS_DOMAIN=${DOCKER_CERTS}/${DOCKER_DOMAIN}
    mkdir -p ${CERTS_DOMAIN}
    CERTBOT_SH=${CERTS_DOMAIN}/certbot.sh
    echo "#!/bin/bash" > ${CERTBOT_SH}
    echo "DOMAIN=${DOCKER_DOMAIN}" >> ${CERTBOT_SH}
    echo "EMAIL=${DOCKER_EMAIL}" >> ${CERTBOT_SH}
    echo "CERTBOT=${DOCKER_CERTBOT}" >> ${CERTBOT_SH}
    echo "CERTLIVE=/etc/letsencrypt/live" >> ${CERTBOT_SH}
    echo "CERTSPATH=/opt/otpkey/certs" >> ${CERTBOT_SH}
    echo 'if [ $CERTBOT == "-certbot" ] || [ $CERTBOT == "certbot" ]; then' >> ${CERTBOT_SH}
    echo 'if [ -f "${CERTSPATH}/${DOMAIN}/privkey.pem" ] || [ -L "${CERTSPATH}/${DOMAIN}/privkey.pem" ]; then' >> ${CERTBOT_SH}
    echo 'echo "certbot use already cert" >> ${CERTSPATH}/${DOMAIN}/certbot.log' >> ${CERTBOT_SH}
    echo 'else' >> ${CERTBOT_SH}
    echo 'echo "certbot will be processed" >> ${CERTSPATH}/${DOMAIN}/certbot.log' >> ${CERTBOT_SH}
    echo 'certbot certonly -v --force-interactive -q --standalone --agree-tos --email ${EMAIL} -d ${DOMAIN}' >> ${CERTBOT_SH}
    echo 'cp -f ${CERTLIVE}/${DOMAIN}/cert.pem ${CERTSPATH}/${DOMAIN}/.' >> ${CERTBOT_SH}
    echo 'cp -f ${CERTLIVE}/${DOMAIN}/chain.pem ${CERTSPATH}/${DOMAIN}/.' >> ${CERTBOT_SH}
    echo 'cp -f ${CERTLIVE}/${DOMAIN}/fullchain.pem ${CERTSPATH}/${DOMAIN}/.' >> ${CERTBOT_SH}
    echo 'cp -f ${CERTLIVE}/${DOMAIN}/privkey.pem ${CERTSPATH}/${DOMAIN}/.' >> ${CERTBOT_SH}
    echo 'fi' >> ${CERTBOT_SH}
    echo 'else' >> ${CERTBOT_SH}
    echo 'echo "certbot do not processed" >> /opt/otpkey/certs/${DOMAIN}/certbot.log' >> ${CERTBOT_SH}
    echo "fi" >> ${CERTBOT_SH}
    chmod +x ${CERTBOT_SH}
}

PROCESSED=0

# 전체 다시 빌드 (캐시 사용안함)
if [ "$1" = "build" ]
then
    if [ -z "$DOCKER_DOMAIN" ] || [ "$DOCKER_DOMAIN" == "-certbot" ] || [ "$DOCKER_DOMAIN" == "certbot" ]
    then
        echo "Need domain"
    else
        certbot
        docker build --no-cache -t $DOCKER_NAME . -f Dockerfile --build-arg DOMAIN="$DOCKER_DOMAIN" --build-arg PUSHURL="$DOCKER_PUSHURL"
        PROCESSED=1
    fi
fi

# 수정된 사항 빌드 (캐시 사용)
if [ "$1" = "make" ]
then
    if [ -z "$DOCKER_DOMAIN" ] || [ "$DOCKER_DOMAIN" == "-certbot" ] || [ "$DOCKER_DOMAIN" == "certbot" ]
    then
        echo "Need domain"
    else
        certbot
        docker build -t $DOCKER_NAME . -f Dockerfile --build-arg DOMAIN="$DOCKER_DOMAIN" --build-arg PUSHURL="$DOCKER_PUSHURL"
        PROCESSED=1
    fi
fi

# 생성된 이미지 실행 (컨테이너가 하나 만들어져서 실행된다)
if [ "$1" = "run" ]
then
    docker run -it -v ${DOCKER_CERTS}:/opt/otpkey/certs --restart always -h $DOCKER_NAME -d --cap-add SYS_NICE -p 80:80 -p 443:443 --name $DOCKER_NAME $DOCKER_NAME --name $DOCKER_CERTBOT $DOCKER_CERTBOT
    PROCESSED=1
fi

# 컨테이너 실행 (정지된 컨터이너를 시작함)
if [ "$1" = "start" ]
then
    docker start $DOCKER_NAME
    PROCESSED=1
fi

# 컨테이너 중지 (실행중인 컨테이너를 중지함)
if [ "$1" = "stop" ]
then
    docker stop $DOCKER_NAME
    PROCESSED=1
fi

# 컨테이너 재가동 (실행중인 컨테이너를 재가동 함)
if [ "$1" = "restart" ]
then
    docker restart $DOCKER_NAME
    PROCESSED=1
fi

# 컨테이너 삭제
if [ "$1" = "rm" ]
then
    docker rm $DOCKER_NAME
    PROCESSED=1
fi

# 실행중인 컨테이너의 쉘로 들어감
if [ "$1" = "bash" ]
then
    docker exec -it $DOCKER_NAME bash
    PROCESSED=1
fi

# 이미지 제거
if [ "$1" = "prune" ]
then
    docker image prune -af
    PROCESSED=1
fi

# 이미지 배치 설치
if [ "$1" = "install" ]
then
    if [ -z "$DOCKER_DOMAIN" ] || [ "$DOCKER_DOMAIN" == "-certbot" ] || [ "$DOCKER_DOMAIN" == "certbot" ]
    then
        echo "Need domain"
    else
        certbot
        docker build --no-cache -t $DOCKER_NAME . -f Dockerfile --build-arg DOMAIN="$DOCKER_DOMAIN" --build-arg PUSHURL="$DOCKER_PUSHURL"

        if [ "$DOCKER_CERTBOT" == "-certbot" ] || [ "$DOCKER_CERTBOT" == "certbot" ]
        then
            if [ -f "${DOCKER_CERTS}/${DOCKER_DOMAIN}/privkey.pem" ] || [ -L "${DOCKER_CERTS}/${DOCKER_DOMAIN}/privkey.pem" ]
            then
            docker run -it -v ${DOCKER_CERTS}:/opt/otpkey/certs --restart always -h $DOCKER_NAME -d --cap-add SYS_NICE -p 80:80 -p 443:443 --name $DOCKER_NAME $DOCKER_NAME --name $DOCKER_CERTBOT $DOCKER_CERTBOT
            echo "Use an existing certificate for ${DOCKER_DOMAIN}"
            else
            docker run -it -v ${DOCKER_CERTS}:/opt/otpkey/certs --restart always -h $DOCKER_NAME -d --cap-add SYS_NICE -p 80:80 -p 443:443 --name $DOCKER_NAME $DOCKER_NAME --name $DOCKER_CERTBOT $DOCKER_CERTBOT
            echo "Restart ${DOCKER_NAME}"
            docker restart $DOCKER_NAME
            fi
        else
            docker run -it -v ${DOCKER_CERTS}:/opt/otpkey/certs --restart always -h $DOCKER_NAME -d --cap-add SYS_NICE -p 80:80 -p 443:443 --name $DOCKER_NAME $DOCKER_NAME --name $DOCKER_CERTBOT $DOCKER_CERTBOT
        fi

        PROCESSED=1
    fi
fi

# 이미지 배치 제거
if [ "$1" = "uninstall" ]
then
    docker stop $DOCKER_NAME
    docker rm $DOCKER_NAME
    docker image prune -af
    PROCESSED=1
fi


if [ $PROCESSED -eq 0 ]
then
    usage
fi