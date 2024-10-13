ARG SAIL_BASE_IMAGE=none

FROM ${SAIL_BASE_IMAGE}

ARG SAIL_GROUP=1000
ARG SAIL_USER=1000
ARG SAIL_PASSWORD

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV TZ=UTC

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update \
    && apt-get install -y --no-install-recommends bash curl openssh-client screen sudo vim wget \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY entrypoint-loop.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/entrypoint-loop.sh

RUN mkdir /tmp/skel
COPY skel /tmp/skel
RUN bash /tmp/skel/custom-rc

#-- usuario: sail
RUN groupadd --force -g ${SAIL_GROUP} sail
RUN useradd -ms /bin/bash --no-user-group -g ${SAIL_GROUP} -u ${SAIL_USER} sail \
    && usermod -aG sudo sail \
    && usermod --password "${SAIL_PASSWORD}" sail \
    && mkdir -p /home/sail/bin \
    && chown -R sail:sail /home/sail
COPY sudoers-sail /etc/sudoers.d/sail
#-- senha: sail
RUN [ -z "${SAIL_PASSWORD}" ] || usermod --password "${SAIL_PASSWORD}" sail
