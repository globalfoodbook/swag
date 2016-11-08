FROM ubuntu:trusty

ENV MY_USER=gfb WEB_USER=www-data NGINX_PATH_PREFIX=/etc/nginx SERVER_URLS="api.globalfoodbook.com api.globalfoodbook.net" DEBIAN_FRONTEND=noninteractive LANG=en_US.UTF-8 LANGUAGE=en_US.en LC_ALL=en_US.UTF-8 NGINX_VERSION=1.9.15 PSOL_VERSION=1.10.33.7 SWAG_IP=127.0.0.1 SWAG_PORT=5121 GOLANG_VERSION=1.7.3 GOLANG_DOWNLOAD_SHA256=508028aac0654e993564b6e2014bf2d4a9751e3b286661b0b0040046cf18028e GOPATH=/go GO_WORKSPACE=bitbucket.org/globalfoodbook PROJECT_NAME=api API_KEY=DCB2A7FB4D1FD97F6CEB6A675

ENV NPS_VERSION=$PSOL_VERSION-beta NGINX_USER=$MY_USER HOME=/home/$MY_USER NGINX_CONF_PATH=$NGINX_PATH_PREFIX/conf NGINX_USER_CONF_PATH=$NGINX_PATH_PREFIX/conf/$MY_USER NGINX_USER_LOG_PATH=$NGINX_PATH_PREFIX/logs/$MY_USER GOLANG_DOWNLOAD_URL=https://golang.org/dl/go$GOLANG_VERSION.linux-amd64.tar.gz PROJECT_DIR=$GOPATH/src/$GO_WORKSPACE/$PROJECT_NAME

ENV SWAG_HOME=$HOME/swagger USER_TEMPLATES_PATH=$HOME/templates NGINX_FLAGS="--with-file-aio --with-ipv6 --with-http_ssl_module  --with-http_realip_module --with-http_addition_module --with-http_xslt_module --with-http_image_filter_module --with-http_geoip_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_degradation_module --with-http_stub_status_module --with-http_perl_module --with-mail --with-mail_ssl_module --with-pcre --with-google_perftools_module --with-debug" PS_NGX_EXTRA_FLAGS="--with-cc=/usr/bin/gcc --with-ld-opt=-static-libstdc++" PATH=$GOPATH/bin:/usr/local/go/bin:$PATH

RUN adduser --disabled-password --gecos "" $MY_USER && echo "$MY_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER $MY_USER

ADD templates/nginx/init.sh /etc/init.d/nginx

# Add all base dependencies
RUN sudo apt-get update -y \
  && sudo apt-get install -y build-essential checkinstall language-pack-en-base vim curl tmux wget unzip libnotify-dev imagemagick libmagickwand-dev libfuse-dev libcurl4-openssl-dev mime-support automake libtool python-docutils libreadline-dev libxslt1-dev libgd2-xpm-dev libgeoip-dev libgoogle-perftools-dev libperl-dev pkg-config libssl-dev git-core subversion phantomjs libgmp-dev zlib1g-dev libxslt-dev libxml2-dev libpcre3 libpcre3-dev freetds-dev openjdk-7-jdk apache2-utils software-properties-common \
  && sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db \
  && sudo apt-get -y update \
  && /bin/bash -l -c "sudo mkdir -p /etc/ngx_pagespeed; cd /etc/ngx_pagespeed; sudo wget https://github.com/pagespeed/ngx_pagespeed/archive/release-${NPS_VERSION}.zip -O /etc/ngx_pagespeed/release-${NPS_VERSION}.zip; sudo unzip release-${NPS_VERSION}.zip -d /etc/ngx_pagespeed; cd /etc/ngx_pagespeed/ngx_pagespeed-release-${NPS_VERSION}/; sudo wget https://dl.google.com/dl/page-speed/psol/${PSOL_VERSION}.tar.gz -O /etc/ngx_pagespeed/ngx_pagespeed-release-${NPS_VERSION}/${PSOL_VERSION}.tar.gz; sudo tar -xzvf /etc/ngx_pagespeed/ngx_pagespeed-release-${NPS_VERSION}/${PSOL_VERSION}.tar.gz" \
  && /bin/bash -l -c "cd ~/ && sudo wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && sudo tar xzf nginx-${NGINX_VERSION}.tar.gz && cd nginx-${NGINX_VERSION} && sudo ./configure --prefix=${NGINX_PATH_PREFIX} --add-module=/etc/ngx_pagespeed/ngx_pagespeed-release-${NPS_VERSION} ${PS_NGX_EXTRA_FLAGS} ${NGINX_FLAGS} && sudo make && sudo make install" \
  && sudo rm $NGINX_PATH_PREFIX/conf/nginx.conf && cd $NGINX_PATH_PREFIX/conf/ \
  && mkdir -p $SWAG_HOME \
  && sudo rm -rf /home/$MY_USER/nginx-${NGINX_VERSION}* \
  && sudo mkdir -p $NGINX_USER_CONF_PATH/configs $NGINX_USER_CONF_PATH/enabled $NGINX_USER_CONF_PATH $NGINX_USER_LOG_PATH \
  && /bin/bash -l -c "sudo chmod +x /etc/init.d/nginx && sudo update-rc.d nginx defaults" && sudo apt-get update -y && sudo apt-get install -y --no-install-recommends \
		g++ \
		gcc \
		libc6-dev \
		make \
	&& sudo rm -rf /var/lib/apt/lists/* && sudo curl -fsSL "$GOLANG_DOWNLOAD_URL" -o golang.tar.gz \
	&& sudo echo "$GOLANG_DOWNLOAD_SHA256  golang.tar.gz" | sha256sum -c - \
	&& sudo tar -C /usr/local -xzf golang.tar.gz \
	&& sudo rm golang.tar.gz && sudo mkdir -p "$GOPATH/src" "$GOPATH/bin" && sudo chmod -R 777 "$GOPATH"

ADD templates/nginx/conf/*.conf ${USER_TEMPLATES_PATH}/conf/
ADD templates/nginx/enabled/*.conf ${USER_TEMPLATES_PATH}/enabled/
ADD templates/nginx/configs/*.conf ${USER_TEMPLATES_PATH}/configs/

ADD templates/entrypoint.sh /etc/entrypoint.sh
RUN sudo chmod +x /etc/entrypoint.sh

# How to extract swagger-ui
# wget https://github.com/swagger-api/swagger-ui/archive/master.zip
# unzip master.zip
# mv swagger-ui-master/dist/* /to/path/of/directory

ADD templates/swagger/ $SWAG_HOME/

WORKDIR $HOME

EXPOSE 80
EXPOSE 5120
EXPOSE $SWAG_PORT

# Setup the entrypoint
ENTRYPOINT ["/bin/bash", "-l", "-c"]
CMD ["/etc/entrypoint.sh"]
