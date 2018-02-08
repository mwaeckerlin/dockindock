FROM mwaeckerlin/ubuntu-base
MAINTAINER Marc Wäckerlin

RUN wget -qO- https://download.docker.com/linux/ubuntu/gpg | apt-key add -
RUN add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
RUN apt-get update && apt-get install -y docker-ce lxc-docker- docker-engine- docker.io-

VOLUME /var/lib/docker
CMD if which cgroups-mount; then \
      cgroups-mount; \
    fi; \
    dockerd
