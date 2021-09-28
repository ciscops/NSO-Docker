# Stage 1 - base OS and NSO

# baseimage is a more Docker-friendly Ubuntu for something like NSO w/multiple child processes
FROM phusion/baseimage:focal-1.1.0 as BaseNSO

ARG build_date=unspecified
ARG nso_ver=5.4.4.3
ARG file_server=0.0.0.0:48888
ARG docker_cli=false
ARG openssh_server=false
# Note some NSO packages/NEDs still require Java 8
ARG java_version=11
ARG nso_java_opts='-Xmx2G -Xms1G'
# The UID & GID need to be unique within the container and should be unique on the host
ARG ncsuser=ncsadmin
ARG ncsuser_uid=8000
ARG ncsgroup=ncsadmin
ARG ncsgroup_gid=9999

# install_dir has to be absolute (used in sed edit below)
ARG install_dir=/nso

LABEL org.opencontainers.image.title="Cisco NSO ${nso_ver}" \
      org.opencontainers.image.description="Cisco NSO ${nso_ver}, local install" \
      org.opencontainers.image.vendor="Cisco Systems" \
      org.opencontainers.image.created="${build_date}" \
      org.opencontainers.image.url="unspecified"

WORKDIR ${install_dir}
EXPOSE 830/tcp 2022/tcp 2024/tcp 8080/tcp

#Uncomment these COPY statements to have the RUN skip some wget operations
COPY requirements.txt /tmp
COPY ssh-config ./.ssh/config
COPY git-credential-helper.sh ./.git-credential-helper.sh
COPY gitconfig ./.gitconfig
COPY nso-${nso_ver}.linux.x86_64.installer.bin /tmp
COPY vimrc ./.vimrc
COPY vim-syntax-yang.tar.gz /tmp/vim-syntax-yang.tar.gz

#SHELL ["/bin/bash", "-c"]

# Use baseimage's init system
CMD ["/sbin/my_init"]
#CMD ["su", "--whitelist-environment=OAUTH_TOKEN,GIT_USERNAME", "-", "${ncsuser}"]

# Install software
RUN echo "======== Updating base OS" && \
    DEBIAN_FRONTEND=noninteractive apt-get -qq update && \
    DEBIAN_FRONTEND=noninteractive apt-get -qq upgrade -o Dpkg::Options::='--force-confold' && \
    \
    echo "======== Installing utilities, Java, Python" && \
    DEBIAN_FRONTEND=noninteractive apt-get install -qq --no-install-recommends wget apt-utils openssh-client openjdk-${java_version}-jre-headless python3 tmux && \
    if [ ! -e /usr/bin/python ]; then ln -s python3 /usr/bin/python ; fi && \
    \
    echo "======== Installing build tools for NSO packages" && \
    DEBIAN_FRONTEND=noninteractive apt-get install -qq --no-install-recommends software-properties-common && \
    DEBIAN_FRONTEND=noninteractive add-apt-repository -y ppa:jonathonf/vim && \
    DEBIAN_FRONTEND=noninteractive apt-get install -qq --no-install-recommends sudo vim git make ant libxml2-utils yang-tools xsltproc && \
    #DEBIAN_FRONTEND=noninteractive apt-get install -qq --no-install-recommends pylint yapf3 && \
    \
    if [ "${docker_cli}" = "true" ]; then \
      echo "======== Installing Docker CLI for Jenkins + CXTA" ; \
      DEBIAN_FRONTEND=noninteractive apt-get install -qq --no-install-recommends curl gnupg-agent software-properties-common ; \
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sh -c 'apt-key add -' ; \
      add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" ; \
      DEBIAN_FRONTEND=noninteractive apt-get install -qq --no-install-recommends docker-ce-cli ; \
    fi && \
    \
    if [ "${openssh_server}" = "true" ]; then \
      echo "======== Enabling SSH server for remote shell access" ; \
      rm -f /etc/service/sshd/down ; \
      #/etc/my_init.d/00_regen_ssh_host_keys.sh ; \
    fi && \
    \
    if [ ! -f /tmp/requirements.txt ]; then \
      echo "======== Fetching local files" ; \
      wget -q --no-proxy http://${file_server}/requirements.txt -O /tmp/requirements.txt ; \
      mkdir .ssh ; \
      wget -q --no-proxy http://${file_server}/ssh-config -O ./.ssh/config ; \
      wget -q --no-proxy http://${file_server}/git-credential-helper.sh -O ./.git-credential-helper.sh ; \
      wget -q --no-proxy http://${file_server}/gitconfig -O ./.gitconfig ; \
      wget -q --no-proxy http://${file_server}/nso-${nso_ver}.linux.x86_64.installer.bin -O /tmp/nso-${nso_ver}.linux.x86_64.installer.bin ; \
      wget -q --no-proxy http://${file_server}/vimrc -O ./.vimrc ; \
      wget -q --no-proxy http://${file_server}/vim-syntax-yang.tar.gz -O /tmp/vim-syntax-yang.tar.gz ; \
    fi && \
    if [ -f /tmp/vim-syntax-yang.tar.gz ]; then \
      tar xzf /tmp/vim-syntax-yang.tar.gz ; \
    fi && \
    \
    echo "======== Installing pip and requirements" && \
    DEBIAN_FRONTEND=noninteractive apt-get install -qq --no-install-recommends python3-pip python3-venv && \
    pip3 install --no-cache --upgrade pip && \
    if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi && \
    python3 -m venv /venv && \
    . /venv/bin/activate && \
    pip3 install --no-cache setuptools wheel && \
    pip3 install --no-cache -r /tmp/requirements.txt && \
    \
    echo "======== Installing NSO ${nso_ver}" && \
    sh /tmp/nso-${nso_ver}.linux.x86_64.installer.bin ${install_dir}/nso-install --local-install && \
    # Normally these keys should be RW only for user, but may need R for group/other in Jenkins pipeline with potentially random user
    chmod 0644 ${install_dir}/nso-install/netsim/confd/etc/confd/ssh/ssh_host_rsa_key && \
    chmod 0644 ${install_dir}/nso-install/etc/ncs/ssh/ssh_host_ed25519_key && \
    rm -rf ${install_dir}/nso-install/{doc,examples.ncs,man,packages,src/ncs/pyapi/doc} && \
    \
    echo "======== OS cleanup" && \
    apt-get -qq autoremove && \
    apt-get -qq clean autoclean && \
    rm -rf /var/lib/apt/lists/{apt,cache,dpkg,log} /usr/share/man /tmp/* /var/tmp/* && \
    \
    echo "======== Creating local ${ncsuser} user" && \
    groupadd -g ${ncsgroup_gid} ${ncsgroup} && \
    useradd -Mu ${ncsuser_uid} -g users -G ${ncsgroup} -d ${install_dir} -s /bin/bash ${ncsuser} && \
    echo "${ncsuser} ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/${ncsuser} && \
    chmod 0440 /etc/sudoers.d/${ncsuser} && \
    echo "PATH=/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> .profile && \
    printf "if [ -f ~/.bashrc ]; then\n  . ~/.bashrc\nfi\n" >> .profile && \
    echo "alias ll=\"ls -l\"" >> .bashrc && \
    echo "source /venv/bin/activate" >> .bashrc && \
    echo "source ${install_dir}/nso-install/ncsrc" >> .bashrc && \
    echo "export NCS_JAVA_VM_OPTIONS=\"${nso_java_opts}\"" >> .bashrc && \
    chown -R ${ncsuser}:users ${install_dir} && \
    \
    echo "======== Finishing up" && \
    chmod 644 /etc/container_environment.sh && \
    sed -i "s,INSTALL_DIR,\\${install_dir}," .gitconfig
