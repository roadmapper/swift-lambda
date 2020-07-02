FROM swift:5.2-amazonlinux2

RUN yum -y install zip \
    && yum clean all \
    && rm -rf /var/cache/yum
