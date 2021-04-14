FROM registry.redhat.io/ubi7/ubi:7.7
LABEL description="This is a custom httpd container image"
MAINTAINER John Doe <jdoe@xyz.com>
RUN yum install -y nc 
RUN echo "******************* first echo command ***********************" && \
    sleep 30 && \
    echo "******************* waking up from sleep ***************************"
EXPOSE 9477 
COPY ./test.sh ./post-hook.sh /
RUN chmod 777 ./post-hook.sh
USER 1001 
ENTRYPOINT ["/test.sh"]
