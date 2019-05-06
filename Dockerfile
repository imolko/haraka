FROM node:6.10

MAINTAINER Yohany Flores <yohanyflores@gmail.com>

LABEL com.imolko.group=imolko
LABEL com.imolko.type=base

# node-gyp emits lots of warnings if HOME is set to /
ENV HOME /tmp

# Versiones de las dependencias.
ENV HARAKA_VERSION 2.8.4
ENV LODASH_VERSION 3.10.1
ENV FOMATTO_VERSION 0.5.0
ENV NODE_INSPECTOR_VERSION 0.12.5
ENV GEARMANODE_VERSION 0.9.1
ENV GEARMANODE_FIX_VERSION git://github.com/veny/GearmaNode.git#1fdb141ebfed0f2688d85c58b2238f82eb9ea8ad
ENV MAXANT_RULES_VERSION 2.1.3
ENV MONGO_VERSION 3.0.11

#     npm install -g "node-inspector@$NODE_INSPECTOR_VERSION" && \

# Dependencias de tarishi en nodejs.
RUN set -x && \
    npm install -g "Haraka@$HARAKA_VERSION" && \
    npm install -g "lodash@$LODASH_VERSION" && \
    npm install -g "fomatto@$FOMATTO_VERSION" && \
    npm install -g "maxant-rules@$MAXANT_RULES_VERSION" && \
    npm install -g "mongodb@${MONGO_VERSION}" && \
    set +x && \
    echo "[INFO] Intentaremos instalar varias versiones de gearmanode, estamos a la espera de la version $GEARMANODE_VERSION" && \
    ( \
        false \
        || npm install -g gearmanode@$GEARMANODE_VERSION \
        || (echo "[WARNING] No se econtro gearmanode@$GEARMANODE_VERSION, intentamos instalar cualquier version mayor a $GEARMANODE_VERSION." && false) \
        || npm install -g gearmanode@">=$GEARMANODE_VERSION" \
        || (echo "[WARNING] No se econtro gearmanode@>=$GEARMANODE_VERSION, intentaremos instalar desde el master." && false ) \
        || npm install -g $GEARMANODE_FIX_VERSION \
    ) && \
    set -x && \
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

