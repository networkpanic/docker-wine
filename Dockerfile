FROM ubuntu:20.10

# Build-time metadata as defined at http://label-schema.org

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="Wine docker" \
      org.label-schema.description="Ubuntu based Wine image" \
      org.label-schema.url="https://networkpanic.github.io" \
      org.label-schema.version=$CI_COMMIT_REF_SLUG \
      org.label-schema.schema-version="1.0"


ENV WINEARCH=win64 \
    WINEDEBUG=-all,err \ 
    DISPLAY=:0.0 \
    WINETRICKS_VERSION=20200412

RUN export DEBIAN_FRONTEND="noninteractive" \
    && echo "Configuring Ubuntu with equired tools for Wine" \
    && apt-get update \
    && apt-get install -yqq --no-install-recommends \
        alsa-oss \
        alsa-utils \
        binutils \
        ca-certificates \
        cabextract \
        curl \
        gnupg2 \
        libasound2 \
        libasound2-plugins \
        p7zip \
        pulseaudio \
        pulseaudio-utils \        
        software-properties-common \
        unzip \
        wget \
        winbind \
        xvfb \
        xz-utils \
        zenity

# Install wine
ARG WINE_BRANCH="stable"
RUN wget -nv -O- https://dl.winehq.org/wine-builds/winehq.key | APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 apt-key add - \
    && apt-add-repository "deb https://dl.winehq.org/wine-builds/ubuntu/ $(grep VERSION_CODENAME= /etc/os-release | cut -d= -f2) main" \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && DEBIAN_FRONTEND="noninteractive" apt-get install -yqq --install-recommends winehq-${WINE_BRANCH} \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/apt/cache/* \
    && rm -rf /tmp/* 

# Download winetricks
RUN curl -L https://raw.githubusercontent.com/Winetricks/winetricks/${WINETRICKS_VERSION}/src/winetricks -o /usr/local/bin/winetricks \
    && chmod +rx /usr/local/bin/winetricks

RUN mkdir -p /home/wine \
    && useradd --system -d /home/wine --shell /bin/bash --uid 1000 --gid root wine \
    && chown -R wine /home/wine

USER wine

WORKDIR /home/wine/gameserver

RUN echo "Initializing the wine environment for the current user" \
    && wine wineboot --init \
    && while pgrep wineserver > /dev/null; do sleep 1; done \
    && winetricks --unattended win10 \
    && echo "Deleting cache files" \
    && rm -rf /home/wine/.cache/*

ENTRYPOINT [ "wine64" ]