ARG SAIL_BASE_IMAGE=none

FROM ${SAIL_BASE_IMAGE}

ARG SAIL_VERSION_CODENAME

ARG SAIL_VERSION=none
ARG SAIL_GROUP=1000
ARG SAIL_USER=1000
ARG SAIL_USERNAME
ARG SAIL_PASSWORD

ARG NODE_VERSION=none

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y \
         jq software-properties-common sudo unrar \
         gnupg gosu ca-certificates zip unzip git supervisor sqlite3 libcap2-bin libpng-dev \
         mysql-client postgresql-client \
    && mkdir -p ~/.gnupg \
    && chmod 600 ~/.gnupg \
    && echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf \
    && apt-key adv --homedir ~/.gnupg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E5267A6C \
    && apt-key adv --homedir ~/.gnupg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C300EE8C \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu ${SAIL_VERSION_CODENAME} main" > /etc/apt/sources.list.d/ppa_ondrej_php.list \
    && apt-get update \
    && apt-get install -y php${SAIL_VERSION}-cli php${SAIL_VERSION}-dev \
       php${SAIL_VERSION}-pgsql php${SAIL_VERSION}-sqlite3 php${SAIL_VERSION}-gd \
       php${SAIL_VERSION}-curl php${SAIL_VERSION}-memcached \
       php${SAIL_VERSION}-imap php${SAIL_VERSION}-mysql php${SAIL_VERSION}-mbstring \
       php${SAIL_VERSION}-xml php${SAIL_VERSION}-zip php${SAIL_VERSION}-bcmath php${SAIL_VERSION}-soap \
       php${SAIL_VERSION}-intl php${SAIL_VERSION}-readline php${SAIL_VERSION}-pcov \
       php${SAIL_VERSION}-msgpack php${SAIL_VERSION}-igbinary php${SAIL_VERSION}-ldap \
       php${SAIL_VERSION}-redis php${SAIL_VERSION}-swoole php${SAIL_VERSION}-xdebug \
    && php -r "readfile('https://getcomposer.org/installer');" | php -- --install-dir=/usr/bin/ --filename=composer \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN curl -sL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get update \
    && apt-get install -y nodejs \
    && npm install -g npm \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && apt-get install -y yarn \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN update-alternatives --set php /usr/bin/php${SAIL_VERSION}
RUN setcap "cap_net_bind_service=+ep" /usr/bin/php${SAIL_VERSION}

#-- sail
RUN [ -z "${SAIL_PASSWORD}" ] || usermod --password "${SAIL_PASSWORD}" sail

RUN mkdir /tmp/skel
COPY skel /tmp/skel
RUN cat /tmp/skel/custom-rc | sed "s/{{USERNAME}}/${SAIL_USERNAME}/g" | bash

COPY init-composer /home/${SAIL_USERNAME}/bin/
RUN chown ${SAIL_USER}:${SAIL_GROUP} /home/${SAIL_USERNAME}/bin/init-composer \
    && chmod 755 /home/${SAIL_USERNAME}/bin/init-composer

COPY start-container /usr/local/bin/start-container
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY php.ini /etc/php/${SAIL_VERSION}/cli/conf.d/99-sail.ini

RUN chmod 755 /usr/local/bin/start-container

USER ${SAIL_USERNAME}
WORKDIR /home/${SAIL_USERNAME}

EXPOSE 8000
ENTRYPOINT ["start-container"]
