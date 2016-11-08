#!/bin/bash

set -e
set -x

export PATH=${GOPATH}/bin:/usr/local/go/bin:/usr/local/bin:${PATH}
export HOST_IP=`awk 'NR==1 {print $1}' /etc/hosts`
if [[ ! ${SQL_MARIADB_DSN} ]]; then
  export SQL_MARIADB_DSN="${MARIADB_ENV_MARIADB_USER}:${MARIADB_ENV_MARIADB_PASSWORD}@${MARIADB_PORT_3306_TCP_PROTO}(${MARIADB_PORT_3306_TCP_ADDR}:${MARIADB_PORT_3306_TCP_PORT})/${MARIADB_ENV_MARIADB_DATABASE}"
fi

if [[ ! ${GFB_API_KEYS} ]]; then
  export GFB_API_KEYS="${API_KEY}"
fi

if [[ $BASIC_PASS && $BASIC_USER ]]; then
  sudo /usr/bin/htpasswd -b -c ${NGINX_PATH_PREFIX}/.htpasswd ${BASIC_USER} ${BASIC_PASS}
fi

sudo cp ${USER_TEMPLATES_PATH}/configs/*.conf ${NGINX_USER_CONF_PATH}/configs;
sudo cp ${USER_TEMPLATES_PATH}/enabled/*.conf ${NGINX_USER_CONF_PATH}/enabled;
sudo cp ${USER_TEMPLATES_PATH}/conf/*.conf ${NGINX_CONF_PATH};

for name in SWAG_IP SWAG_PORT SWAG_HOME NGINX_USER NGINX_PATH_PREFIX SERVER_URLS MY_USER HOST_IP NGINX_USER_CONF_PATH NGINX_USER_LOG_PATH NGINX_CONF_PATH
do
  eval value=\$$name;
  sudo sed -i "s|\${${name}}|${value}|g" ${NGINX_CONF_PATH}/nginx.conf;
  sudo sed -i "s|\${${name}}|${value}|g" ${NGINX_USER_CONF_PATH}/configs/default.conf;
  sudo sed -i "s|\${${name}}|${value}|g" ${NGINX_USER_CONF_PATH}/enabled/80.conf;
  sudo sed -i "s|\${${name}}|${value}|g" ${NGINX_USER_CONF_PATH}/enabled/5120.conf;
done

echo -e Environment variables setup completed;

sudo chown -R ${NGINX_USER}:${NGINX_USER} ${SWAG_HOME}/ > /dev/null 2>&1 &
sudo find ${SWAG_HOME}/ -type d -exec chmod 755 {} \; > /dev/null 2>&1 &
sudo find ${SWAG_HOME}/ -type f -exec chmod 644 {} \; > /dev/null 2>&1 &

echo -e Permissions setup completed;

sudo service nginx start > /dev/null 2>&1 &

echo -e Ngnix start up is complete;

if [ -d "${PROJECT_DIR}" ]; then

  if [ -f "/go/bin/${PROJECT_NAME}" ]; then
    rm -rf /go/bin/${PROJECT_NAME}
  fi

  if [[ $MARIADB_PORT_3306_TCP_ADDR ]]; then
    counter=0;
    while ! nc -vz $MARIADB_PORT_3306_TCP_ADDR $MARIADB_PORT_3306_TCP_PORT; do
      counter=$((counter+1));
      if [ $counter -eq 6 ]; then break; fi;
      sleep 10;
    done

    cd ${PROJECT_DIR} && go get github.com/tools/godep && godep restore && go install

    echo -e "**** Start gfb service api ***"
    cp -R /go/src/${GO_WORKSPACE}/${PROJECT_NAME}/docs/ /go/bin/
    PORT=${SWAG_PORT} /go/bin/${PROJECT_NAME} &
  fi
fi

echo -e Ngnix start up is complete;

sudo touch ${NGINX_USER_LOG_PATH}/access.log ${NGINX_USER_LOG_PATH}/error.log
sudo tail -F ${NGINX_USER_LOG_PATH}/access.log ${NGINX_USER_LOG_PATH}/error.log
