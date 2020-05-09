FROM ubuntu:latest AS downloader
RUN apt-get update && apt-get install -y \
    unzip

WORKDIR /tmp

#download base omeka and extract
ADD https://github.com/omeka/omeka-s/releases/download/v2.1.2/omeka-s-2.1.2.zip /tmp/
RUN unzip -q /tmp/omeka-s-2.1.2.zip -d /tmp/


FROM php:apache
# allow rewrite
RUN a2enmod rewrite

# update and upgrade
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -qq update \
    && apt-get -qq -y upgrade

RUN apt-get -qq update \ 
    && apt-get -qq -y --no-install-recommends install \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng-dev \
    libjpeg-dev \
    libmemcached-dev \
    zlib1g-dev \
    imagemagick \
    libmagickwand-dev

# php extensions
RUN docker-php-ext-install -j$(nproc) iconv pdo pdo_mysql mysqli gd
RUN pecl install mcrypt-1.0.3 \
    && docker-php-ext-enable mcrypt \
    && pecl install imagick \
    && docker-php-ext-enable imagick

RUN rm -rf /var/www/html/

# add omeka-s
COPY --from=downloader /tmp/omeka-s /var/www/html/

RUN rm -rf /var/www/html/config/

COPY ./database.ini /var/www/html/config/database.ini
COPY ./.htaccess /var/www/html/.htaccess

RUN chmod +rwx -R /var/www/html/

COPY ./imagemagick-policy.xml /etc/ImageMagick/policy.xml

CMD ["apache2-foreground"]