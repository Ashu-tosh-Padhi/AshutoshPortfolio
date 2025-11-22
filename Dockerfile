# Start from the official Apache HTTP server image
FROM httpd:2.4

COPY . /tmp/app


RUN rm -rf /usr/local/apache2/htdocs/* && \
    cp -r /tmp/app/* /usr/local/apache2/htdocs/

EXPOSE 80
