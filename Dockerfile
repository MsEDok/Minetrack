FROM node:20-slim

ARG TINI_VER="v0.19.0"
ARG HOST_UID=568
ARG HOST_GID=568

# Install tini and sqlite3
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl sqlite3 ca-certificates \
 && curl -L https://github.com/krallin/tini/releases/download/${TINI_VER}/tini -o /sbin/tini \
 && chmod +x /sbin/tini \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /usr/src/minetrack

# Copy files
COPY . .

# Build project
RUN npm ci --build-from-source \
 && npm run build

# Create a user that matches the host UID/GID
RUN groupadd --gid ${HOST_GID} minetrack \
 && useradd --uid ${HOST_UID} --gid ${HOST_GID} --system --no-create-home --shell /usr/sbin/nologin minetrack \
 && chown -R minetrack:minetrack /usr/src/minetrack

USER minetrack

EXPOSE 8080

ENTRYPOINT ["/sbin/tini", "--", "node", "main.js"]
