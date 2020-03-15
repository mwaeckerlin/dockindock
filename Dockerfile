FROM mwaeckerlin/ubuntu-base
MAINTAINER mwaeckerlin

# connect volume to:
#   -v /var/run/docker.sock:/var/run/docker.sock

# set to the group id of docker group in your system
# set to the value of command:
#   getent group docker | cut -d: -f3
ENV DOCKER_GROUP_ID 999

ENV CONTAINERNAME="dockindock"

RUN apt-get update \
 && apt-get install --no-install-recommends --no-install-suggests -y docker.io \
 && /cleanup.sh

VOLUME /var/lib/docker
ADD start-dockindock.sh /start-dockindock.sh
