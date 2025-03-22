FROM ubuntu:bionic

# install dependencies
RUN apt update && \
    DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC \
    apt install -y --no-install-recommends \
    apache2 \
    ca-certificates \
    certbot \
    cron \
    curl \
    default-libmysqlclient-dev \
    dh-autoreconf \
    g++ \
    git \
    jq \
    libapache2-mod-php \
    libcurl4-gnutls-dev \
    libssl-dev \
    logrotate \
    m4 \
    mc \
    make \
    mariadb-client \
    mariadb-server \
    openssl \
    php \
    php-cli \
    php-gd \
    php-mysql \
    php-xml \
    pkg-config \
    python \
    python-mysqldb \
    python3 \
    python3-certbot-apache \
    python3-mysqldb \
    python3-venv \
    rsyslog \
    sudo \
    supervisor \
    unzip \
    wget

# copy config files
COPY 50-server.cnf /etc/mysql/mariadb.conf.d/
COPY supervisord.conf /etc/supervisor/conf.d/

# install boinc
RUN git clone https://github.com/BOINC/boinc.git /usr/local/boinc
RUN cd /usr/local/boinc && ./_autosetup && ./configure --disable-client --disable-manager && make

# configure apache
RUN a2enmod cgi proxy proxy_http proxy_balancer lbmethod_byrequests
RUN echo "ServerName 127.0.0.1" >> /etc/apache2/apache2.conf

# create user
RUN adduser boincadm --disabled-password --gecos "" && \
    usermod -a -G boincadm www-data

CMD [ "/usr/bin/supervisord" ]
