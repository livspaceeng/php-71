FROM ubuntu:xenial-20181113
MAINTAINER Vyshakh P vyshakh.p@livspace.com

ENV OS_LOCALE="en_US.UTF-8"
RUN apt-get update && apt-get install -y locales && locale-gen ${OS_LOCALE}
ENV LANG=${OS_LOCALE} \
LANGUAGE=${OS_LOCALE} \
LC_ALL=${OS_LOCALE} \
DEBIAN_FRONTEND=noninteractive

#RUN apt-get update && sudo apt-get upgrade
RUN BUILD_DEPS='software-properties-common python-software-properties' \
&& dpkg-reconfigure locales \
&& apt-get install --no-install-recommends -y $BUILD_DEPS
RUN apt-get update && apt-get -y upgrade

RUN add-apt-repository -y ppa:ondrej/php \
&& add-apt-repository -y ppa:ondrej/apache2 \
&& apt-get update && apt-get -y upgrade

RUN add-apt-repository ppa:ondrej/php
RUN add-apt-repository ppa:chris-lea/redis-server
RUN apt-get update && apt-get -y upgrade

RUN apt-get install -y --force-yes apache2 memcached php7.1-common php7.1-dev php7.1-json php7.1-opcache php7.1-cli libapache2-mod-php7.1
RUN apt-get install -y --force-yes php7.1 php7.1-mysql php7.1-fpm php7.1-curl php7.1-gd php7.1-mcrypt php7.1-mbstring
RUN apt-get install -y --force-yes php7.1-bcmath php7.1-zip php-memcached php7.1-xml php7.1-yaml
RUN apt-get install -y --force-yes php7.1-soap

#-- Configure PHP &Apache --
RUN sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.1/apache2/php.ini
RUN sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.1/apache2/php.ini
RUN a2enmod rewrite

ENV APACHE_CONF_DIR=/etc/apache2
ENV PHP_CONF_DIR=/etc/php/7.1

RUN  apt-get purge -y --auto-remove $BUILD_DEPS && apt-get autoremove -y
RUN touch /var/log/apache2/access.log && touch /var/log/apache2/error.log
RUN rm -rf /var/lib/apt/lists/*

# Apache settings
RUN rm ${APACHE_CONF_DIR}/sites-enabled/000-default.conf ${APACHE_CONF_DIR}/sites-available/000-default.conf
# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --version=1.6.4 --install-dir=/usr/local/bin --filename=composer

RUN touch /var/log/apache2/access.log && touch /var/log/apache2/error.log
RUN rm -rf /var/lib/apt/lists/*

# Forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/apache2/access.log
RUN ln -sf /dev/stderr /var/log/apache2/error.log
RUN mkdir -p /var/www
RUN chown www-data:www-data /var/www -Rf

COPY docker/configs/apache2.conf ${APACHE_CONF_DIR}/apache2.conf
COPY docker/configs/app.conf ${APACHE_CONF_DIR}/sites-enabled/app.conf
COPY docker/configs/php.ini ${PHP_CONF_DIR}/apache2/conf.d/custom.ini
COPY docker/entrypoint.sh /sbin/entrypoint.sh

RUN chmod 755 /sbin/entrypoint.sh
RUN a2enmod headers rewrite expires remoteip

WORKDIR /var/www/app/
EXPOSE 80 443

# By default, simply start apache.
CMD ["/sbin/entrypoint.sh"]
