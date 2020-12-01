FROM registry.redhat.io/ubi7/ubi:7.7
LABEL description="This is a custom httpd container image"
MAINTAINER John Doe <jdoe@xyz.com>
RUN yum install -y nc 
EXPOSE 9477 
COPY ./test.sh /
USER 1001 
ENTRYPOINT ["/test.sh"]
