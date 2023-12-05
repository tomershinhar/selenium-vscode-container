FROM registry.fedoraproject.org/fedora:39-x86_64
LABEL maintainer="tshinhar@redhat.com"

COPY init.go .

COPY settings.json /home/selenium/.local/share/code-server/User/settings.json

# Firefox releases
# https://download-installer.cdn.mozilla.net/pub/firefox/releases/
ARG FIREFOX_VERSION="115.1.0esr"
# Gecko driver releases
# https://github.com/mozilla/geckodriver/releases
ARG GECKODRIVER_VERSION="v0.33.0"
# Chrome versions
# https://www.ubuntuupdates.org/package/google_chrome/stable/main/base/google-chrome-stable
ARG CHROME_VERSION="112.0.5615.121"

ARG SELENIUM_MAJOR_VERSION=4

ARG SELENIUM_MINOR_VERSION=8

ARG SELENIUM_PATCH_VERSION=3

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
        java-11-openjdk-headless \
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

RUN curl -LO https://download-installer.cdn.mozilla.net/pub/firefox/releases/${FIREFOX_VERSION}/linux-x86_64/en-US/firefox-${FIREFOX_VERSION}.tar.bz2 && \
    tar -C . -xjvf firefox-${FIREFOX_VERSION}.tar.bz2 && \
    rm -f firefox-${FIREFOX_VERSION}.tar.bz2

RUN curl -LO https://github.com/mozilla/geckodriver/releases/download/${GECKODRIVER_VERSION}/geckodriver-${GECKODRIVER_VERSION}-linux64.tar.gz && \
    tar -C /usr/bin/ -xvf geckodriver-${GECKODRIVER_VERSION}-linux64.tar.gz && \
    rm -f geckodriver-${GECKODRIVER_VERSION}-linux64.tar.gz

# install code-server	
RUN curl -fsSL https://code-server.dev/install.sh | sh

# install ansible extension
RUN code-server --install-extension redhat.ansible 

# set up work directory for vs-code
RUN mkdir -p workspace && touch workspace/playbook.yaml


# enable FIPS mode for NSS
RUN modutil -fips true -dbdir /etc/pki/nssdb -force && \
    chown -R 0:0 /etc/pki/nssdb && \
    chmod 644 /etc/pki/nssdb/*

RUN chown -R 1001:0 ${SELENIUM_HOME} && \
    chmod -R g=u ${SELENIUM_HOME}

USER 1001

# run init.go to start all process in order
CMD ["sh", "-c", "go run /init.go" ]
