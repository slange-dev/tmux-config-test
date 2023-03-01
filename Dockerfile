FROM debian:11-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    fontconfig \
    git \
    gcc \
    iputils-ping \
    libevent-dev \
    libncurses-dev \
    locales \
    make \
    procps \
    wget \
  && wget -O - https://github.com/tmux/tmux/releases/download/3.3a/tmux-3.3a.tar.gz | tar xzf - \
  && cd tmux-3.3a \
  && LDFLAGS="-L/usr/local/lib -Wl,-rpath=/usr/local/lib" ./configure --prefix=/usr/local \
  && make \
  && make install \
  && cd .. \
  && rm -rf tmux-3.3a \
  && apt-get purge -y gcc make \
  && apt-get -y autoremove \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
  && locale-gen
ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8

WORKDIR /root

RUN mkdir -p /.fonts $HOME/.config/fontconfig/conf.d \
  && wget -P /.fonts https://github.com/powerline/powerline/raw/develop/font/PowerlineSymbols.otf \
  && wget -P /.config/fontconfig/conf.d/ https://github.com/powerline/powerline/raw/develop/font/10-powerline-symbols.conf \
  && fc-cache -vf /.fonts/

RUN git clone https://github.com/slange-dev/tmux-config-testings \
  && chmod +x /tmux-config-testings/install.sh \
  && source /tmux-config-testings/install.sh \
  && rm -rf /tmux-config-testings

ENV TERM=xterm-256color
