FROM alpine:latest

ARG VERSION=not-specified

RUN set -x \
 && alias l='ls -la' \
 && cd /opt \
 && apk add --no-cache curl sed yarn bash jq git npm \
 && wget -O /etc/apk/keys/adoptium.rsa.pub https://packages.adoptium.net/artifactory/api/security/keypair/public/repositories/apk \
 && echo 'https://packages.adoptium.net/artifactory/apk/alpine/main' >> /etc/apk/repositories \
 && apk add temurin-17-jdk \
 && curl -L -O https://github.com/clojure/brew-install/releases/latest/download/linux-install.sh \
 && chmod +x linux-install.sh \
 && ./linux-install.sh \
 && rm linux-install.sh \
 && babashka_version=$(curl -s https://api.github.com/repos/babashka/babashka/releases/latest | jq -r .tag_name | sed -e "s/^v//") \
 && wget "https://github.com/babashka/babashka/releases/download/v${babashka_version}/babashka-${babashka_version}-linux-amd64-static.tar.gz" -O babashka.tar.gz \
 && tar -xzf babashka.tar.gz -C /usr/local/bin/ \
 && rm babashka.tar.gz \
 && git clone https://github.com/logseq/publish-spa \
 && cd publish-spa \
 && yarn install \
 && yarn global add $PWD \
 && cd /opt \
 && git clone --branch "${VERSION}" --single-branch https://github.com/logseq/logseq logseq \
 && cd logseq \
 && yarn install --frozen-lockfile \
 && yarn gulp:build \
 && clojure -M:cljs release publishing \
 && ln -s /opt/logseq/ /logseq \
 && echo "#!/usr/bin/env bash" > /start.sh \
 && echo "cd /repo" >> /start.sh \
 && echo "logseq-publish-spa /export" >> /start.sh \
 && echo '[ -n "${PUBLISH_UID_GID}" ] && chown -R "${PUBLISH_UID_GID}" /export || echo -n ""' >> /start.sh \
 && chmod +x /start.sh

WORKDIR /repo
VOLUME ["/repo","/export"]
ENTRYPOINT ["/start.sh"]
