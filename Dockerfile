FROM centos:8
MAINTAINER "Shigeki Kitamura" <kitamura@procube.jp>
RUN groupadd -g 111 builder
RUN useradd -g builder -u 111 builder
ENV HOME /home/builder
WORKDIR ${HOME}
ENV SHIBBOLETH_VERSION "3.0.4-1"
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Linux-*
RUN sed  -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-Linux-*
#COPY CentOS-Linux-AppStream.repo CentOS-Linux-BaseOS.repo CentOS-Linux-ContinuousRelease.repo CentOS-Linux-Debuginfo.repo CentOS-Linux-Devel.repo CentOS-Linux-Extras.repo CentOS-Linux-FastTrack.repo CentOS-Linux-HighAvailability.repo CentOS-Linux-Media.repo CentOS-Linux-Plus.repo CentOS-Linux-PowerTools.repo CentOS-Linux-Sources.repo /etc/yum.repos.d/
RUN yum -y update \
    && yum -y install unzip wget sudo lsof openssh-clients telnet bind-utils tar tcpdump vim initscripts \
         gcc openssl-devel zlib-devel pcre-devel rpmdevtools make drpm yum-utils \
         systemd-devel chrpath unixODBC-devel httpd-devel gcc-c++ boost-devel gdb
RUN dnf -y --enablerepo=powertools install doxygen libmemcached-devel
RUN mkdir -p /tmp/requires \
    && cd /tmp/requires/ \
    && wget --no-verbose -O /tmp/requires/lua.tar.gz https://github.com/procube-open/lua51-el8/releases/download/1.0.0/lua51-el8.tar.gz \
    && tar xvzf lua.tar.gz \
    && cd RPMS/x86_64/ \
    && rpm -ivh lua-5.1.4-15.el8.x86_64.rpm lua-devel-5.1.4-15.el8.x86_64.rpm
ADD shibboleth.repo /etc/yum.repos.d
RUN yum -y install libxml-security-c-devel libxmltooling-devel-3.0.4-4.1 libsaml-devel-3.0.1-4.1 liblog4shib-devel \
       xmltooling-schemas-3.0.4-4.1 opensaml-schemas-3.0.1-4.1 memcached libmemcached
RUN yum -y install epel-release
RUN yum -y install fcgi-devel
RUN mkdir -p /tmp/buffer
RUN mkdir -p /tmp/rpms
RUN yumdownloader --destdir /tmp/rpms liblog4shib2 libsaml10 libsaml-devel-3.0.1-4.1 libxml-security-c20 \
     libxmltooling8-3.0.4-4.1 opensaml-schemas-3.0.1-4.1 xmltooling-schemas-3.0.4-4.1 libxerces-c-3_2 libxmltooling-devel-3.0.4-4.1 liblog4shib-devel \
     libxml-security-c-devel libxerces-c-devel supervisor fcgi
COPY shibboleth.spec.patch /tmp/buffer/
COPY logger.patch /tmp/buffer/
COPY shibresponder.patch /tmp/buffer/
USER builder
RUN mkdir -p ${HOME}/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
RUN echo "%_topdir %(echo ${HOME})/rpmbuild" > ${HOME}/.rpmmacros
RUN mkdir ${HOME}/srpms \
    && cd srpms \
    && wget https://mirrors.rit.edu/shibboleth/CentOS_8/src/shibboleth-${SHIBBOLETH_VERSION}.src.rpm \
    && rpm -ivh shibboleth-${SHIBBOLETH_VERSION}.src.rpm
RUN cp /tmp/buffer/logger.patch rpmbuild/SOURCES
RUN cp /tmp/buffer/shibresponder.patch rpmbuild/SOURCES
RUN cd rpmbuild/SPECS \
    && patch -p 1 shibboleth.spec < /tmp/buffer/shibboleth.spec.patch
COPY build.sh .
CMD ["/bin/bash","./build.sh"]
