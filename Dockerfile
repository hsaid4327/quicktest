FROM registry.redhat.io/ubi7/ubi:7.7
LABEL description="This is a custom httpd container image"
MAINTAINER John Doe <jdoe@xyz.com>
ARG myVar=myvariable
ENV var1=var1value
ENV tdv_base_dir=${APP_DEV_PROPERTIES:TDV_BASE_DIR}
RUN yum install -y nc
EXPOSE 9477
COPY ./test.sh ./post-hook.sh test.out /
RUN chmod 777 ./post-hook.sh && \
    mkdir -p /scripts && \
    mkdir -p /archive && \
    chmod 777 test.out


COPY ./scripts/* /scripts
COPY ./archive/Utilities_2021Q100 /archive/Utilities_2021Q100
RUN chown -R 1001:1001 /scripts && \
    chown -R 1001:1001 /archive && \
    chmod ugo+x /scripts/*.sh
USER 1001
RUN ./scripts/setup.sh ${tdv_base_dir} "key2"
ENTRYPOINT ["/test.sh"]
