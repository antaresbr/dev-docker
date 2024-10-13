ARG SAIL_BASE_IMAGE=none

FROM ${SAIL_BASE_IMAGE}

ARG SAIL_GROUP=1000
ARG SAIL_USER=1000
ARG SAIL_USERNAME=node
ARG SAIL_PASSWORD

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV TZ=UTC

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update \
    && apt-get install -y --no-install-recommends bash ca-certificates curl gnupg jq openssh-client screen sudo unrar-free vim wget \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY entrypoint-loop.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/entrypoint-loop.sh

RUN mkdir /tmp/skel
COPY skel /tmp/skel
RUN cat /tmp/skel/custom-rc | sed "s/{{USERNAME}}/${SAIL_USERNAME}/g" | bash

#-- usuario: sail
RUN groupadd --force --gid ${SAIL_USER} ${SAIL_USERNAME}
RUN getent passwd ${SAIL_USER} > /dev/null || useradd --create-home --shell /bin/bash --uid ${SAIL_USER} --gid ${SAIL_USER} ${SAIL_USERNAME}
RUN usermod -aG sudo ${SAIL_USERNAME} \
    && mkdir -p /home/${SAIL_USERNAME}/bin \
    && chown -R ${SAIL_USER}:${SAIL_GROUP} /home/${SAIL_USERNAME}

COPY sudoers-sail /etc/sudoers.d/${SAIL_USERNAME}
RUN sed -i "s/{{USERNAME}}/${SAIL_USERNAME}/g" /etc/sudoers.d/${SAIL_USERNAME}

#-- senha: sail
RUN [ -z "${SAIL_PASSWORD}" ] || usermod --password "${SAIL_PASSWORD}" ${SAIL_USERNAME}

COPY init-node.sh /home/${SAIL_USERNAME}/bin
RUN chown -R ${SAIL_USER}:${SAIL_GROUP} /home/${SAIL_USERNAME}

USER ${SAIL_USERNAME}
WORKDIR /home/${SAIL_USERNAME}
