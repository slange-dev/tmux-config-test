# Set the base image to Debian 12 slim
FROM debian:12-slim

# Maintainer
LABEL org.opencontainers.image.authors="slange-dev"

# Version
LABEL version="0.1"

# Install dependencies and build tmux
RUN apt update && apt install -y --no-install-recommends \
    bc \
    build-essential \
    bison \
    byacc \
    ca-certificates \
    fontconfig \
    git \
    gcc \
    iputils-ping \
    libevent-dev \
    libncurses-dev \
    locales \
    make \
    pkg-config \
    procps \
    wget \
    vlock \
    yacc \
  && wget -O - https://github.com/tmux/tmux/releases/download/3.5a/tmux-3.5a.tar.gz | tar xzf - \
  && cd tmux-3.5a \
  && LDFLAGS="-L/usr/local/lib -Wl,-rpath=/usr/local/lib" ./configure --prefix=/usr/local \
  && make \
  && make install \
  && cd .. \
  && rm -rf tmux-3.5a \
  && apt purge -y gcc make \
  && apt -y autoremove \
  && apt clean \
  && rm -rf /var/lib/apt/lists/*

# Set language
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
  && locale-gen

# Set language env
ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8

# Set user env to root
ENV USER=root

# Set term env to *-256 colors
ENV TERM=xterm-256color

# Set workdir
WORKDIR /root

# Set shell to bash
SHELL ["/bin/bash", "-c"]

# Install Powerline symbols and fonts
#RUN mkdir -p /usr/local/share/fonts/powerline /usr/share/fontconfig/conf.avail \
#&&
RUN wget -P /usr/local/share/fonts/powerline https://github.com/powerline/powerline/raw/develop/font/PowerlineSymbols.otf \
  && wget -P /usr/share/fontconfig/conf.avail https://github.com/powerline/powerline/raw/develop/font/10-powerline-symbols.conf \
  && ln -s /usr/share/fontconfig/conf.avail/10-powerline-symbols.conf /etc/fonts/conf.d/10-powerline-symbols.conf \
  && fc-cache -vf /usr/local/share/fonts/powerline

# Install tmux config files from tmux testing repository
RUN mkdir -p ~/tmux-config-testings \
  && git clone https://github.com/slange-dev/tmux-config-testings ~/tmux-config-testings \
  && chmod +x ~/tmux-config-testings/install.sh \
  && source ~/tmux-config-testings/install.sh

# Copy tmux start script
COPY run_tmux.sh run_tmux.sh

# Run tmux
ENTRYPOINT ["/bin/bash", "run_tmux.sh"]
