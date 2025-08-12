FROM httpd:2.4

RUN apt-get update && apt clean\
    && rm -rf /var/lib/apt/lists/*

RUN cp -r /var/lib/jenkins/workspace/CICD-Pipeline/* /usr/local/apache2/htdocs/