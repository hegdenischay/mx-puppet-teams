FROM node:15.0-alpine3.12 AS builder

WORKDIR /opt/mx-puppet-teams

RUN apk --no-cache add git python2 make g++ pkgconfig \
    build-base \
    cairo-dev \
    jpeg-dev \
    pango-dev \
    musl-dev \
    giflib-dev \
    pixman-dev \
    pangomm-dev \
    libjpeg-turbo-dev \
    freetype-dev

# run build process as user in case of npm pre hooks
# pre hooks are not executed while running as root
RUN chown -R node:node /opt/mx-puppet-teams
USER node

COPY --chown=node:node package.json package-lock.json ./
RUN npm install

COPY --chown=node:node tsconfig.json ./
COPY --chown=node:node src/ ./src/
RUN npm run build


FROM node:15.0-alpine3.12

VOLUME /data

ENV CONFIG_PATH=/data/config.yaml \
    REGISTRATION_PATH=/data/msteams-registration.yaml

RUN apk add --no-cache su-exec \
    cairo \
    jpeg \
    pango \
    sl \
    giflib \
    pixman \
    pangomm \
    libjpeg-turbo \
    freetype

WORKDIR /opt/mx-puppet-teams
COPY docker-run.sh ./
COPY --from=builder /opt/mx-puppet-teams/node_modules/ ./node_modules/
COPY --from=builder /opt/mx-puppet-teams/build/ ./build/

# change workdir to /data so relative paths in the config.yaml
# point to the persisten volume
WORKDIR /data
ENTRYPOINT ["/opt/mx-puppet-teams/docker-run.sh"]