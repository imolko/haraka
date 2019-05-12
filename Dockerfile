FROM node:6.10

MAINTAINER Yohany Flores <yohanyflores@gmail.com>

LABEL com.imolko.group=imolko
LABEL com.imolko.type=base

# node-gyp emits lots of warnings if HOME is set to /
ENV HOME /tmp

# Versiones de las dependencias.
ENV HARAKA_VERSION 2.8.4

#     npm install -g "node-inspector@$NODE_INSPECTOR_VERSION" && \

# Dependencias de tarishi en nodejs.
RUN set -x && \
    npm install -g "Haraka@$HARAKA_VERSION" && \
    npm cache clean && \
    rm -rf /tmp/*

# grab gosu for easy step-down from root
RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN	wget --output-document /usr/local/bin/gosu.asc --quiet "https://github.com/tianon/gosu/releases/download/1.5/gosu-$(dpkg --print-architecture).asc" \
    && wget --output-document /usr/local/bin/gosu --quiet "https://github.com/tianon/gosu/releases/download/1.5/gosu-$(dpkg --print-architecture)" \
    && gpg --verify /usr/local/bin/gosu.asc \
    && rm /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu

# Creamos un script para haraka debug
RUN echo '#!/bin/bash' > "$( readlink -f $( which haraka ) )_debug" \
    && echo "$( readlink -f $( which node )) --debug=5858 \"$( readlink -f $( which haraka ) )\" \"\$@\"" >> "$( readlink -f $( which haraka ) )_debug" \
    && chmod +x "$( readlink -f $( which haraka ) )_debug" \
    && chown "nobody:root" "$( readlink -f $( which haraka ) )_debug" \
    && ln -s "$( readlink -f $( which haraka ) )_debug" "$( which haraka )_debug"

# Variable de entorno para haraka
ENV HARAKA_HOME /haraka

# creamos un usuario y un grupo haraka y la carpeta home.
RUN set -x && \
    groupadd -r haraka && \
    useradd --comment "Haraka Server User" \
            --home "$HARAKA_HOME" \
            --shell /bin/false \
            --gid haraka \
            -r \
            -M \
            haraka && \
    mkdir -p "$HARAKA_HOME" && \
    cd "$HARAKA_HOME" && \
    haraka -install "$HARAKA_HOME"

# Instalamos cliente bash para rabbitmq
RUN printf "deb http://archive.debian.org/debian/ jessie main\ndeb-src http://archive.debian.org/debian/ jessie main\ndeb http://security.debian.org jessie/updates main\ndeb-src http://security.debian.org jessie/updates main" > /etc/apt/sources.list
RUN set -x && apt-get update && apt-get install -y amqp-tools --no-install-recommends && rm -rf /var/lib/apt/lists/*

ENV HOME "$HARAKA_HOME"

WORKDIR /haraka

COPY config/smtp.ini /haraka/config/smtp.ini

RUN  chmod -R 0777 "$HARAKA_HOME" && \
     chown -R haraka:haraka "$HARAKA_HOME"

# VOLUME [ "/haraka" ]

# Configuramos el Entrypoint
COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 2525
EXPOSE 9080

# Colocamos este path para garantizar un nombre largo en el comando.
# Y poder ver las estadisticas correctamente.
CMD ["-c", "/haraka/././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././"]

#configuramos la zona horaria
RUN echo "America/Caracas" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata

