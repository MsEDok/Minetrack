FROM node:16

ARG TINI_VER="v0.19.0"
ARG HOST_UID=568
ARG HOST_GID=568

# install tini
ADD https://github.com/krallin/tini/releases/download/$TINI_VER/tini /sbin/tini
RUN chmod +x /sbin/tini

# install sqlite3
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends sqlite3 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# copy files
WORKDIR /usr/src/minetrack
COPY . .

# build project
RUN npm install --build-from-source \
 && npm run build

# create a user that matches the host UID/GID
RUN groupadd --gid ${HOST_GID} minetrack \
 && useradd --uid ${HOST_UID} --gid ${HOST_GID} --system --no-create-home --shell /usr/sbin/nologin minetrack \
 && chown -R minetrack:minetrack /usr/src/minetrack
USER minetrack

EXPOSE 8080
ENTRYPOINT ["/sbin/tini", "--", "node", "main.js"]
