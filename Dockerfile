FROM mwaeckerlin/ubuntu-base
MAINTAINER Marc Wäckerlin

RUN apt-get update && apt-get install -y docker.io

VOLUME /var/lib/docker
CMD cgroups-mount && docker
