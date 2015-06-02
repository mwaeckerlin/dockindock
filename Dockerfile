FROM ubuntu:latest
MAINTAINER Marc Wäckerlin

RUN apt-get install -y apt-transport-https
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
RUN sh -c "echo deb https://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list"
RUN apt-get update -y
RUN apt-get install -y lxc-docker

VOLUME /var/lib/docker
CMD cgroups-mount && docker -d