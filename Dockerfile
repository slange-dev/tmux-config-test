# Set the base image to Debian 12 slim
FROM debian:12-slim

# Maintainer
LABEL maintainer="slange-dev" \
  org.opencontainers.image.authors="slange-dev" \
  org.opencontainers.image.title="tmux-config-testings" \
  org.opencontainers.image.description="Tmux config testings" \
  org.opencontainers.image.source="https://github.com/slange-dev/tmux-config-testings"

# Version
LABEL version="0.1"

# Set workdir
WORKDIR /root

# Install dependencies and build tmux
RUN apt-get update && apt-get install -y --no-install-recommends \
  bc=1.07.1-3+b1 \
  build-essential=12.9 \
  bison=2:3.8.2+dfsg-1+b1 \
  byacc=1:2.0.20221106-1 \
  ca-certificates=20230311 \
  fontconfig=2.14.1-4 \
  git=1:2.39.5-0+deb12u1 \
  gcc=4:12.2.0-3 \
  iputils-ping=3:20221126-1+deb12u1 \
  libevent-dev=2.1.12-stable-8 \
  libncurses-dev=6.4-4 \
  locales=2.36-9+deb12u9 \
  make=4.3-4.1 \
  pkg-config=1.8.1-1 \
  procps=2:4.0.2-3 \
  wget=1.21.3-1+b2 \
  vlock=2.2.2-11+b1 \
  && wget -O - https://github.com/tmux/tmux/releases/download/3.5a/tmux-3.5a.tar.gz | tar xzf - \
  && cd tmux-3.5a \
  && LDFLAGS="-L/usr/local/lib -Wl,-rpath=/usr/local/lib" ./configure --prefix=/usr/local \
  && make \
  && make install \
  && cd .. \
  && rm -rf tmux-3.5a \
  && apt-get purge -y gcc make \
  && apt-get autoremove -y \
  && apt-get clean -y \
  && apt-get autoclean -y \
  && rm -rf /var/lib/apt/lists/*

# Set language
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
  && locale-gen

# Set language env
ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8

# Set user env to root
ENV USER=root

# Set term env to xterm-256 colors
ENV TERM=xterm-256color

# Set shell to bash with -c
SHELL ["/bin/bash", "-c"]

# Install Powerline symbols and fonts
RUN wget -P /usr/local/share/fonts/powerline https://github.com/powerline/powerline/raw/develop/font/PowerlineSymbols.otf \
  && wget -P /usr/share/fontconfig/conf.avail https://github.com/powerline/powerline/raw/develop/font/10-powerline-symbols.conf \
  && ln -s /usr/share/fontconfig/conf.avail/10-powerline-symbols.conf /etc/fonts/conf.d/10-powerline-symbols.conf \
  && fc-cache -vf /usr/local/share/fonts/powerline

# Install tmux config files from tmux testing repository
RUN mkdir -p tmux-config-testings \
  && git clone https://github.com/slange-dev/tmux-config-testings tmux-config-testings \
  && chmod +x tmux-config-testings/install.sh \
  && source tmux-config-testings/install.sh

# Copy tmux start script
COPY run_tmux.sh run_tmux.sh

# Set shell env to bash
ENV SHELL=/bin/bash

# Run tmux
ENTRYPOINT ["/bin/bash", "run_tmux.sh"]
