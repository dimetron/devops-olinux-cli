FROM oraclelinux:8-slim
MAINTAINER Dmytro Rashko <drashko@me.com>

## Environment variables required for this build (do NOT change)
ENV VERSION_OC=3.11.0
ENV VERSION_HELM2=2.13.1
ENV VERSION_HELM3=3.1.2
ENV SDKMAN_DIR=/root/.sdkman
ENV TERM=xterm-color

ENV HELM2_BASE_URL="https://storage.googleapis.com/kubernetes-helm"
ENV HELM2_TAR_FILE="helm-v${VERSION_HELM2}-linux-amd64.tar.gz"

ENV HELM3_BASE_URL="https://get.helm.sh"
ENV HELM3_TAR_FILE="helm-v${VERSION_HELM3}-linux-amd64.tar.gz"

# set environment variables
RUN echo "LANG=en_US.utf-8" >> /etc/environment \
 && echo "LC_ALL=en_US.utf-8" >> /etc/environment

#Install cli tools
COPY docker-ce.repo /etc/yum.repos.d/docker-ce.repo 
RUN rpm -ivh  https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

RUN echo "Installing additional software" \ 
    && ls /usr/bin \
    && microdnf -y install --enablerepo=docker-ce-stable  yum-utils device-mapper-persistent-data lvm2 docker-ce vim-minimal which wget zip unzip jq tar passwd \
                openssh openssh-server squid bash sshpass hostname curl ca-certificates libstdc++ ca-certificates bash git zip unzip sed \
                python36 openssl bash zsh procps rsync mc openssh skopeo findutils jq \
    && microdnf -y clean all \
    && rm -rf /var/lib/{cache,log} /var/log/lastlog \
    && mkdir /var/log/lastlog

RUN curl -sLo ./kind "https://github.com/kubernetes-sigs/kind/releases/download/v0.7.0/kind-$(uname)-amd64" \
    && mv kind  /usr/bin \
    && chmod +x /usr/bin/kind

RUN curl -sL "${HELM2_BASE_URL}/${HELM2_TAR_FILE}" | tar xvz && \
    mv linux-amd64/helm /usr/bin/helm2 && \
    chmod +x /usr/bin/helm2 &&            \
    rm -rf linux-amd64

RUN curl -sL "${HELM3_BASE_URL}/${HELM3_TAR_FILE}" | tar xvz && \
    mv linux-amd64/helm /usr/bin/helm3 && \
    chmod +x /usr/bin/helm3 &&            \
    rm -rf linux-amd64

RUN ln -s /usr/bin/helm3 /usr/bin/helm

# Add oc 
RUN curl -sL "https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz" | tar xvz && \
    cp openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit/* /usr/bin/ && \
    rm -rf openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit/

RUN curl -sL "https://github.com/derailed/k9s/releases/download/v0.19.2/k9s_Linux_x86_64.tar.gz" | tar xvz && \
    mv k9s /usr/bin/

#install terraform
RUN curl -sL "https://releases.hashicorp.com/terraform/0.12.24/terraform_0.12.24_linux_amd64.zip" -o terraform.zip \
    && unzip terraform.zip -d /usr/bin \
    && chmod +x /usr/bin

#add aws
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install      \
    && rm -rf  ./aws

RUN rpm -ivh https://github.com/wagoodman/dive/releases/download/v0.9.2/dive_0.9.2_linux_amd64.rpm

#install ZSH custom theme
RUN sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"

RUN env && bash --version && \
    curl -s "https://get.sdkman.io" | /bin/bash && \
    echo "sdkman_auto_answer=true" > $SDKMAN_DIR/etc/config && \
    echo "sdkman_auto_selfupdate=false" >> $SDKMAN_DIR/etc/config && \
    echo "sdkman_insecure_ssl=true" >> $SDKMAN_DIR/etc/config

#install maven and java 8
RUN zsh -c 'set +x;source /root/.sdkman/bin/sdkman-init.sh'
RUN zsh -c 'source "/root/.sdkman/bin/sdkman-init.sh" && sdk install maven'
RUN zsh -c 'source "/root/.sdkman/bin/sdkman-init.sh" && sdk ls java && sdk install java 8.0.252-amzn'

#install krew for kubectl
RUN curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew.{tar.gz,yaml}" \
    && tar zxvf krew.tar.gz ; cat krew.yaml \
    && ./krew-linux_amd64 install --manifest=krew.yaml --archive=krew.tar.gz \
    && ./krew-linux_amd64 update

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/.sdkman/bin:/root/.sdkman/candidates/maven/current/bin:/root/.krew/bin

#use openssh 
RUN  sed -i s/#PermitRootLogin.*/PermitRootLogin\ yes/ /etc/ssh/sshd_config  \
  && sed -i s/#PermitTunnel.*/PermitTunnel\ yes/ /etc/ssh/sshd_config  \
  && sed -i s/#AllowTcpForwarding.*/AllowTcpForwarding\ yes/ /etc/ssh/sshd_config  \
  && cat /etc/ssh/sshd_config

#add custom user
ADD https://github.com/dimetron.keys /root/.ssh/authorized_keys
RUN passwd -d root && \
    ssh-keygen -A

COPY rootfs /

ENTRYPOINT ["/entrypoint.sh"]
WORKDIR /root

CMD ['/bin/sh']
