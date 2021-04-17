FROM registry.redhat.io/ubi7/ubi:7.7
LABEL description="This is a custom httpd container image"
MAINTAINER John Doe <jdoe@xyz.com>
RUN yum install -y nc
EXPOSE 9477
COPY ./test.sh ./post-hook.sh /
RUN chmod 777 ./post-hook.sh && \
    mkdir -p /scripts && \
    mkdir -p /archive


COPY ./scripts/* /scripts
COPY ./archive/Utilities_2021Q100 /archive/Utilities_2021Q100
RUN chown -R 1001:1001 /scripts && \
    chown -R 1001:1001 /archive && \
    chmod ugo+x /scripts/*.sh
USER 1001
RUN /scripts/setup.sh "key1" "key2"
ENTRYPOINT ["/test.sh"]
