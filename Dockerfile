FROM mwaeckerlin/ubuntu-base
MAINTAINER mwaeckerlin

RUN apt-get update \
    && apt-get install -y wget lsb-release software-properties-common \
    && wget -qO- https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    && apt-get update \
    && apt-get install -y docker-ce lxc-docker- docker-engine- docker.io- wget- lsb-release- software-properties-common-

VOLUME /var/lib/docker
ADD start-dockindock.sh /start-dockindock.sh
