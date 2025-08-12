# Start from the official Apache HTTP server image
FROM httpd:2.4

# Install git (requires apt and a few dependencies)
RUN apt-get update && \
    apt-get install -y git && \
    rm -rf /var/lib/apt/lists/*

# Clone the app into a temp folder
COPY . /tmp/app


RUN rm -rf /usr/local/apache2/htdocs/* && \
    cp -r /tmp/app/* /usr/local/apache2/htdocs/

# Expose port 80
EXPOSE 80