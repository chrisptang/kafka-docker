#!/bin/sh
# usage:
# ./compose.sh docker-compose args, e.g:
# ./compose.sh start cat

if [ -e ./.env ]
then 
    echo "---- please check current .env file:"
    cat ./.env
    echo "---- ./.env ended"
else
    export HOST_IP=`ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p' | grep -v '.0.1$'`
    export HOST_IP_PUBLIC=`curl --connect-timeout 2 --max-time 5 https://ifconfig.co/ip`

    if [ -z "$HOST_IP_PUBLIC" ]
    then
        printf "=====\n=====\nCould not get public IP from https://ifconfig.co/ip, fullback env variable HOST_IP_PUBLIC to 127.0.0.1\n=====\n"
        export HOST_IP_PUBLIC="127.0.0.1"
    fi

    cat /dev/null > ./.env
    echo "HOST_IP=$HOST_IP" >> ./.env
    echo "HOST_IP_PUBLIC=$HOST_IP_PUBLIC" >> ./.env
    echo "WEIXIN_BOT=https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=f9743577-b399-4989-acd8-516400860292"  >> ./.env

    cat ./.env
fi

if [ -x "$(command -v docker)" ]; then
    echo "docker has properly installed."
else 
    echo "Installing docker"
    curl -fsSL https://get.docker.com | bash -s docker
    sudo apt install -y docker-compose
    sudo groupadd docker
    sudo usermod -aG docker $USER
fi

start () {
    echo "starting:${1} ......"

    docker-compose -f ${1} up -d --remove-orphans
    docker ps
}

stop () {
    echo "stopping:${1} ......"
    docker-compose -f ${1} stop
}

main () {
    echo "--- script start $0 $1 $2 $(date +'%Y-%m-%d %H:%M:%S')"

    # $0: $HOME/java.sh, $1: action (start, stop, restart) , $2: docker-compose file surfix, e.g.: (local,dev,test,apollo,cat,...)
    SCRIPT=$0
    ACTION=$1
    COMPOSE=$2

    if [ -z "$COMPOSE" ]
    then
        COMPOSE="docker-compose.yml"
    else
        COMPOSE="docker-compose-${COMPOSE}.yml"
    fi

    case "$ACTION" in
        "start")
            start ${COMPOSE}
        ;;
        "stop")
            stop ${COMPOSE}
        ;;
        "restart")
            stop ${COMPOSE}
            start ${COMPOSE}
            ;;
        *)
            error "$SCRIPT: supported actions: start, stop, restart"
            ;;
    esac

    echo "--- script end $0 $1 $2 $3 $(date +'%Y-%m-%d %H:%M:%S')"
}

main "$@"