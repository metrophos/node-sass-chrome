# JFROG -----------------------------------

FROM golang:1.13.8-alpine as builder
WORKDIR /tmp/src/github.com/jfrog/jfrog-cli-go
RUN apk update && apk add --no-cache git

# checkout the latest tag of jfrog cli
RUN mkdir -p /tmp/src/github.com/jfrog/jfrog-cli-go && \
    git clone https://github.com/jfrog/jfrog-cli /tmp/src/github.com/jfrog/jfrog-cli-go && \
    cd /tmp/src/github.com/jfrog/jfrog-cli-go && \
    git checkout $(git describe --tags `git rev-list --tags --max-count=1`)

RUN sh /tmp/src/github.com/jfrog/jfrog-cli-go/build.sh

FROM node:13.8.0-alpine
RUN apk add --no-cache bash tzdata ca-certificates
COPY --from=builder /tmp/src/github.com/jfrog/jfrog-cli-go/jfrog /usr/bin/jfrog
RUN chmod +x /usr/bin/jfrog

# JFROG END -------------------------------


# NODE-SASS -------------------------------

RUN apk update && \
    apk upgrade && \
    apk add --no-cache git g++ gcc libgcc libstdc++ linux-headers make python && \
    apk update && \
    npm i npm@latest -g

# install libsass
RUN git clone https://github.com/sass/sassc && cd sassc && \
    git clone https://github.com/sass/libsass && \
    SASS_LIBSASS_PATH=/sassc/libsass make && \
    mv bin/sassc /usr/bin/sassc && \
    cd ../ && rm -rf /sassc

# created node-sass binary
ENV SASS_BINARY_PATH=/usr/lib/node_modules/node-sass/build/Release/binding.node
RUN git clone --recursive https://github.com/sass/node-sass.git && \
    cd node-sass && \
    git submodule update --init --recursive && \
    npm install && \
    node scripts/build -f && \
    cd ../ && rm -rf node-sass

# add binary path of node-sass to .npmrc
RUN touch $HOME/.npmrc && echo "sass_binary_cache=${SASS_BINARY_PATH}" >> $HOME/.npmrc

ENV SKIP_SASS_BINARY_DOWNLOAD_FOR_CI true
ENV SKIP_NODE_SASS_TESTS true

# NODE-SASS END ---------------------------


# SERENITY-CLI ----------------------------

RUN npm i serenity-cli -g && \
    serenity update

# SERENITY-CLI END ------------------------


# CHROMIUM AND CHROMEDRIVER ---------------

RUN \
  echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
  && echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories \
  && echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
  && apk add --no-cache \
  python \
  build-base \
  git \
  bash \
  openjdk8-jre-base \
  nss \
  chromium-chromedriver \
  chromium \
  && apk upgrade --no-cache --available

ENV CHROME_BIN /usr/bin/chromium-browser

# CHROMIUM AND CHROMEDRIVER END -----------
