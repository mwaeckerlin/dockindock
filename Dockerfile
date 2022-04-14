FROM mwaeckerlin/very-base as build
RUN $PKG_INSTALL docker shadow-uidmap fuse-overlayfs slirp4netns iproute2
RUN echo ${RUN_USER}:31072:65536 >> /etc/subuid
RUN echo ${RUN_USER}:31072:65536 >> /etc/subgid
USER ${RUN_USER}
RUN wget -qO- https://get.docker.com/rootless | sed 's/curl .*-o /wget -qO/' | SKIP_IPTABLES=1 sh

FROM mwaeckerlin/scratch
ENV CONTAINERNAME "dockindock"
ENV XDG_RUNTIME_DIR "/home/somebody/.docker/run"
ENV PATH "/home/somebody/bin:$PATH"
ENV DOCKER_HOST "unix:///home/somebody/.docker/run/docker.sock"
ENV SKIP_IPTABLES 1
COPY --from=build / /
CMD /home/somebody/bin/dockerd-rootless.sh
