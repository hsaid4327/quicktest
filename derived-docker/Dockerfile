FROM quicktest-1.0:latest
LABEL description="This is a custom httpd container image"
MAINTAINER John Doe <jdoe@xyz.com>

RUN chown -R 1001:1001 /scripts && \
    chown -R 1001:1001 /archive && \
    chmod ugo+x /scripts/*.sh && \
    touch test.out && \
    echo "This is the arg: $arg >test.out
