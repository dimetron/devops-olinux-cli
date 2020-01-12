FROM oraclelinux:8
MAINTAINER Dmytro Rashko <drashko@me.com>

## Environment variables required for this build (do NOT change)
ENV VERSION_OC=3.11.0
ENV VERSION_HELM=2.13.1
ENV SDKMAN_DIR=/root/.sdkman
ENV TERM=xterm-color

ENV BASE_URL="https://storage.googleapis.com/kubernetes-helm"
ENV TAR_FILE="helm-v${VERSION_HELM}-linux-amd64.tar.gz"

# set environment variables
RUN echo "LANG=en_US.utf-8" >> /etc/environment \
 && echo "LC_ALL=en_US.utf-8" >> /etc/environment

#Install OpenJDK with all  dependencies
RUN echo "Installing dependencies" \
    dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm \
    dnf install https://rpmfind.net/linux/fedora/linux/releases/31/Everything/x86_64/os/Packages/s/sshpass-1.06-8.fc31.x86_64.rpm

RUN echo "Installing additional software" \ 
    && yum -y install vim-minimal which wget zip unzip tar passwd openssh openssh-server bash hostname curl ca-certificates libstdc++ ca-certificates bash git zip unzip python36 openssl bash zsh procps rsync mc openssh \
    && yum -y clean all \
    && rm -rf /var/lib/{cache,log} /var/log/lastlog \
    && mkdir /var/log/lastlog



#install ZSH custom theme
RUN sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"

RUN curl -L "${BASE_URL}/${TAR_FILE}" | tar xvz && \
    mv linux-amd64/helm /usr/bin/helm && \
    chmod +x /usr/bin/helm && \
    rm -rf linux-amd64

# Add oc 
RUN curl -L "https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz" | tar xvz && \
    cp openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit/* /usr/bin/ && \
    rm -rf openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit/

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/.sdkman/bin:/root/.sdkman/candidates/maven/current/bin

RUN env && bash --version && \
    curl -s "https://get.sdkman.io" | /bin/bash && \
    echo "sdkman_auto_answer=true" > $SDKMAN_DIR/etc/config && \
    echo "sdkman_auto_selfupdate=false" >> $SDKMAN_DIR/etc/config && \
    echo "sdkman_insecure_ssl=true" >> $SDKMAN_DIR/etc/config

#install maven and java 8
RUN bash -c 'source "/root/.sdkman/bin/sdkman-init.sh" && sdk install maven && sdk ls java && sdk install java 8.0.232-amzn'

#use openssh 
RUN  sed -i s/#PermitRootLogin.*/PermitRootLogin\ yes/ /etc/ssh/sshd_config  \
  && sed -i s/#PermitTunnel.*/PermitTunnel\ yes/ /etc/ssh/sshd_config  \
  && sed -i s/#AllowTcpForwarding.*/AllowTcpForwarding\ yes/ /etc/ssh/sshd_config  \
  && cat /etc/ssh/sshd_config

#add custom user
ADD https://github.com/dimetron.keys /root/.ssh/authorized_keys
RUN passwd -d root && \
    which sshd    && \
    ssh-keygen -A

EXPOSE 22
COPY rootfs /
ENTRYPOINT ["/entrypoint.sh"]