FROM quay.io/jupyterhub/jupyterhub
#FROM quay.io/jupyterhub/k8s-hub:3.2.1

ENV USER handl2
ENV USER_HOME /home/${USER}

#RUN apt update
#RUN for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do apt remove $pkg; done \
#    && apt update && apt install -y \
#        ca-certificates curl \
#    && install -m 0755 -d /etc/apt/keyrings \
#    && curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc \
#    && chmod a+r /etc/apt/keyrings/docker.asc \
#    && echo \
#        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
#        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
#        tee /etc/apt/sources.list.d/docker.list > /dev/null \
#    && apt update && apt install -y \
#        docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

#RUN apt install -y strace sudo
#
RUN groupadd --gid 1000 ${USER} \
    && useradd --uid 1000 --create-home --home-dir ${USER_HOME} -s /bin/bash -g ${USER} ${USER} \
    && usermod -aG sudo ${USER} \
#    && usermod -aG docker ${USER} \
    && chown -R ${USER}:${USER} ${USER_HOME} \
    && echo "${USER}:${USER}" | chpasswd

#ENV USER_A alice
#ENV USER_A_HOME /home/${USER_A}
#
#RUN groupadd --gid 1001 ${USER_A} \
#    && useradd --uid 1001 --create-home --home-dir ${USER_A_HOME} -s /bin/bash -g ${USER_A} ${USER_A} \
#    && chown -R ${USER_A}:${USER_A} ${USER_A_HOME} \
#    && echo "${USER_A}:${USER_A}" | chpasswd

#RUN pip install dockerspawner

RUN pip install jupyterhub-kubespawner

RUN apt update && apt install -y --no-install-recommends \
        vim htop

RUN chown -R ${USER}:${USER} /srv/jupyterhub

RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chown ${USER}:${USER} kubectl \
    && chmod +x kubectl

USER root

#COPY kubeconfig /home/jovyan/.kube/config

COPY --chown=${USER}:${USER} kubespawner /opt/kubespawner
RUN pip install -e /opt/kubespawner

COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

#USER ${USER}

ENTRYPOINT ["/docker-entrypoint.sh"]
#ENTRYPOINT ["jupyterhub", "--config", "/usr/local/etc/jupyterhub/jupyterhub_config.py"]
