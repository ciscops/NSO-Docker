# Stage 1 - base OS and NSO

FROM ubuntu:20.04 as BaseNSO

ARG build_date=unspecified
ARG nso_ver=5.4.2
ARG file_server=0.0.0.0:48888
ARG docker_cli=false

# install_dir has to be absolute (used in sed edit below)
ARG install_dir=/nso

LABEL org.opencontainers.image.title="Cisco-NSO" \
      org.opencontainers.image.description="Cisco NSO testing" \
      org.opencontainers.image.vendor="Cisco Systems" \
      org.opencontainers.image.created="${build_date}" \
      org.opencontainers.image.url="unspecified"

WORKDIR ${install_dir}
EXPOSE 2022/tcp 2024/tcp 8080/tcp

#Uncomment these COPY statements to have the RUN skip some wget operations
COPY requirements.txt /tmp
COPY ssh-config ./.ssh/config
COPY git-credential-helper.sh ./.git-credential-helper.sh
COPY gitconfig ./.gitconfig
COPY nso-${nso_ver}.linux.x86_64.installer.bin /tmp

#SHELL ["/bin/bash", "-c"]

# Install software
RUN echo "======== Updating base OS" && \
    apt-get -qq update && \
    apt-get -qq upgrade && \
    \
    echo "======== Installing utilities, Java, Python" && \
    DEBIAN_FRONTEND=noninteractive apt-get install -qq --no-install-recommends wget apt-utils openssh-client default-jdk-headless python3 tmux && \
    if [ ! -e /usr/bin/python ]; then ln -s python3 /usr/bin/python ; fi && \
    \
    echo "======== Installing build tools for NSO packages" && \
    DEBIAN_FRONTEND=noninteractive apt-get install -qq --no-install-recommends sudo vim git make ant libxml2-utils xsltproc && \
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
    if [ ! -e /tmp/requirements.txt ]; then \
      echo "======== Fetching local files" ; \
      wget -q --no-proxy http://${file_server}/requirements.txt -O /tmp/requirements.txt ; \
      mkdir .ssh ; \
      wget -q --no-proxy http://${file_server}/ssh-config -O ./.ssh/config ; \
      wget -q --no-proxy http://${file_server}/git-credential-helper.sh -O ./.git-credential-helper.sh ; \
      wget -q --no-proxy http://${file_server}/gitconfig -O ./.gitconfig ; \
      wget -q --no-proxy http://${file_server}/nso-${nso_ver}.linux.x86_64.installer.bin -O /tmp/nso-${nso_ver}.linux.x86_64.installer.bin ; \
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
    \
    echo "======== OS cleanup" && \
    apt-get -qq autoremove && \
    apt-get -qq clean autoclean && \
    rm -rf /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/* && \
    \
    echo "======== Creating local ncsadmin user" && \
    useradd -d ${install_dir} -s /bin/bash -U -M ncsadmin && \
    echo "ncsadmin ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/ncsadmin && \
    chmod 0440 /etc/sudoers.d/ncsadmin && \
    echo "PATH=/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> .profile && \
    echo "if [ -f ~/.bashrc ]; then\n  . ~/.bashrc\nfi\n" >> .profile && \
    echo "source ${install_dir}/nso-install/ncsrc" >> .bashrc && \
    chown -R ncsadmin:ncsadmin ${install_dir} && \
    \
    echo "======== Finishing up" && \
    sed -i'' "s/INSTALL_DIR/\\${install_dir}/" .gitconfig

CMD ["su", "--whitelist-environment=OAUTH_TOKEN,GIT_USERNAME", "-", "ncsadmin"]
