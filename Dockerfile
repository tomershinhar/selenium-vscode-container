FROM registry.fedoraproject.org/fedora:43-x86_64 AS selenium-vscode
LABEL maintainer="goneri@redhat.com"

COPY init.go .

COPY settings.json /home/selenium/.local/share/code-server/User/settings.json

# Firefox releases
# https://download-installer.cdn.mozilla.net/pub/firefox/releases/
ARG FIREFOX_URL="https://download-installer.cdn.mozilla.net/pub/firefox/releases/140.9.1esr/linux-x86_64/en-US/firefox-140.9.1esr.tar.xz"
# Gecko driver releases
# https://github.com/mozilla/geckodriver/releases
ARG GECKODRIVER_VERSION="v0.37.0"
# Chrome versions
# https://www.ubuntuupdates.org/package/google_chrome/stable/main/base/google-chrome-stable
ARG CHROME_VERSION="149.0.7827.196-1"

ARG SELENIUM_MAJOR_VERSION=4

ARG SELENIUM_MINOR_VERSION=45

ARG SELENIUM_PATCH_VERSION=0

ENV SELENIUM_HOME=/home/selenium

ENV SELENIUM_PORT=4444 \
    SELENIUM_SESSION_TIMEOUT=1800 \
    VNC_PORT=5999 \
    API_PORT=8000 \
    DISPLAY=:99 \
    DBUS_SESSION_BUS_ADDRESS=/dev/null \
    HOME=${SELENIUM_HOME} \
    VNC_GEOMETRY=${VNC_GEOMETRY:-"1600x900"} \
    SELENIUM_VERSION=${SELENIUM_MAJOR_VERSION}.${SELENIUM_MINOR_VERSION}.${SELENIUM_PATCH_VERSION} \
    SELENIUM_PATH=${SELENIUM_HOME}/selenium-server/selenium-server-standalone.jar \
    SELENIUM_HTTP_JDK_CLIENT_PATH=${SELENIUM_HOME}/selenium-server/selenium-http-jdk-client.jar \
    PATH=${SELENIUM_HOME}/firefox:/opt/google/chrome:${PATH}

EXPOSE ${SELENIUM_PORT}

EXPOSE ${VNC_PORT}

EXPOSE ${API_PORT}

WORKDIR ${SELENIUM_HOME}

RUN PACKAGES="\
        alsa-lib \
        at-spi2-atk \
        at-spi2-core \
        atk \
        avahi-libs \
        bzip2 \
        cairo \
        cairo-gobject \
        cups-libs \
        dbus-glib \
        dbus-libs \
        expat \
        fluxbox \
        fontconfig \
        freetype \
        fribidi \
        gdk-pixbuf2 \
        graphite2 \
        gtk3 \
        go \
        harfbuzz \
        imlib2 \
        java-latest-openjdk-headless \
        jq \
        libcloudproviders \
        libdatrie \
        libdrm \
        libepoxy \
        liberation-fonts \
        liberation-fonts-common \
        liberation-mono-fonts \
        liberation-sans-fonts \
        liberation-serif-fonts \
        libfontenc \
        libglvnd \
        libglvnd-glx \
        libICE \
        libjpeg-turbo \
        libpng \
        libSM \
        libthai \
        libwayland-client \
        libwayland-cursor \
        libwayland-egl \
        libwayland-server \
        libwebp \
        libX11 \
        libX11-common \
        libX11-xcb \
        libXau \
        libxcb \
        libXcomposite \
        libXcursor \
        libXdamage \
        libXdmcp \
        libXext \
        libXfixes \
        libXfont2 \
        libXft \
        libXi \
        libXinerama \
        libxkbcommon \
        libxkbfile \
        libXpm \
        libXrandr \
        libXrender \
        libXtst \
        libxshmfence \
        libXt \
        mesa-libgbm \
        nspr \
        nss \
        nss-softokn \
        nss-softokn-freebl \
        nss-util \
        nss-tools \
        nss-sysinit \
        pango \
        pixman \
        tar \
        tigervnc-server-minimal \
        tzdata-java \
        unzip \
        vulkan-loader \
        wget \
        xdg-utils \
        xkbcomp \
        xkeyboard-config" && \
    dnf install -y ${PACKAGES}


RUN mkdir -p .cache/dconf .mozilla/plugins .vnc/ .fluxbox/ && \
    echo "session.screen0.toolbar.autoHide: true" > .fluxbox/init && \
    touch .Xauthority .vnc/config

RUN mkdir -p ${SELENIUM_HOME}/selenium-server && \
    curl -L https://github.com/SeleniumHQ/selenium/releases/download/selenium-${SELENIUM_MAJOR_VERSION}.${SELENIUM_MINOR_VERSION}.0/selenium-server-${SELENIUM_VERSION}.jar \
        -o ${SELENIUM_PATH} && \
    curl -L https://repo1.maven.org/maven2/org/seleniumhq/selenium/selenium-http-jdk-client/${SELENIUM_VERSION}/selenium-http-jdk-client-${SELENIUM_VERSION}.jar \
        -o ${SELENIUM_HTTP_JDK_CLIENT_PATH}

RUN curl -L https://download-installer.cdn.mozilla.net/pub/firefox/releases/140.9.1esr/linux-x86_64/en-US/firefox-140.9.1esr.tar.xz|tar --xz -x

RUN curl -LO https://github.com/mozilla/geckodriver/releases/download/${GECKODRIVER_VERSION}/geckodriver-${GECKODRIVER_VERSION}-linux64.tar.gz && \
    tar -C /usr/bin/ -xvf geckodriver-${GECKODRIVER_VERSION}-linux64.tar.gz && \
    rm -f geckodriver-${GECKODRIVER_VERSION}-linux64.tar.gz

RUN echo -e '[google-chrome]\nname=google-chrome\nbaseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64\nenabled=1\ngpgcheck=1\ngpgkey=https://dl.google.com/linux/linux_signing_key.pub' > /etc/yum.repos.d/google-chrome.repo && \
    dnf install -y google-chrome-stable-${CHROME_VERSION}

RUN CHROME_DRIVER_VERSION=$(echo ${CHROME_VERSION} | sed 's/-[0-9]*$//') && \
    curl -LO "https://storage.googleapis.com/chrome-for-testing-public/${CHROME_DRIVER_VERSION}/linux64/chromedriver-linux64.zip" && \
    unzip chromedriver-linux64.zip && \
    mv chromedriver-linux64/chromedriver /usr/bin/chromedriver && \
    chmod +x /usr/bin/chromedriver && \
    rm -rf chromedriver-linux64.zip chromedriver-linux64

# install code-server
RUN curl -fsSL https://code-server.dev/install.sh | sh

# download ansible extension file
RUN export download_url=$(curl -s https://open-vsx.org/api/redhat/ansible | jq -r '.files.download') && \
    curl -L ${download_url} -o ansible-latest.vsix

# download redhat auth extension file
RUN export download_url=$(curl -s https://open-vsx.org/api/redhat/vscode-redhat-account | jq -r '.files.download') && \
    curl -L ${download_url} -o rh-auth-latest.vsix

# install vs-code extensions
RUN code-server --install-extension ansible-latest.vsix && code-server --install-extension rh-auth-latest.vsix

# set up work directory for vs-code
RUN mkdir -p workspace && touch workspace/playbook.yaml


# enable FIPS mode for NSS
RUN modutil -fips true -dbdir /etc/pki/nssdb -force && \
    chown -R 0:0 /etc/pki/nssdb && \
    chmod 644 /etc/pki/nssdb/*

RUN chown -R 1001:0 ${SELENIUM_HOME} && \
    chmod -R g=u ${SELENIUM_HOME}

USER 1001

# install packages needed for go file
RUN go vet /init.go

# run init.go to start all process in order
CMD ["sh", "-c", "go run /init.go" ]


FROM selenium-vscode as selenium-vscode-multi

# get extension files
COPY vscode-inline-suggestion-sample-0.0.1.vsix .
RUN code-server --install-extension vscode-inline-suggestion-sample-0.0.1.vsix
