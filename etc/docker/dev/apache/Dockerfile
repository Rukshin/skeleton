ARG APACHE_VERSION="2.4-alpine"

FROM httpd:${APACHE_VERSION}

COPY vhosts.conf /usr/local/apache2/conf/extra/httpd-vhosts.conf

RUN true \
 && sed -i "/^#LoadModule \(proxy\|proxy_fcgi\|rewrite\)_module/s/^#//g" /usr/local/apache2/conf/httpd.conf \
 && sed -i '/^#Include conf\/extra\/httpd-vhosts.conf/s/^#//g' /usr/local/apache2/conf/httpd.conf \
;
