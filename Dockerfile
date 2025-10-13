FROM node:20-slim

ARG TINI_VER="v0.19.0"
ARG HOST_UID=568
ARG HOST_GID=568

# Install tini, sqlite3, and dependencies
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl sqlite3 ca-certificates git build-essential python3 \
 && curl -fsSL -o /sbin/tini https://github.com/krallin/tini/releases/download/${TINI_VER}/tini \
 && chmod +x /sbin/tini \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /usr/src/minetrack

# Copy package files first for efficient caching
COPY package*.json ./

# Install dependencies (no forced source builds — lets Node 20 prebuilds work)
RUN npm ci

# Copy the rest of the source
COPY . .

# Build the project
RUN npm run build

# Create a user matching host UID/GID
RUN groupadd --gid ${HOST_GID} minetrack \
 && useradd --uid ${HOST_UID} --gid ${HOST_GID} --system --no-create-home --shell /usr/sbin/nologin minetrack \
 && chown -R minetrack:minetrack /usr/src/minetrack

USER minetrack

EXPOSE 8080

ENTRYPOINT ["/sbin/tini", "--", "node", "main.js"]
