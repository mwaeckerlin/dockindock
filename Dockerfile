FROM mwaeckerlin/ubuntu-base
MAINTAINER mwaeckerlin

RUN wget -qO- https://download.docker.com/linux/ubuntu/gpg | apt-key add -
RUN add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
RUN apt-get update && apt-get install -y docker-ce lxc-docker- docker-engine- docker.io-

VOLUME /var/lib/docker
ADD start-dockindock.sh /start-dockindock.sh
CMD /start-dockindock.sh -f
