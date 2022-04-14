FROM mwaeckerlin/very-base as build
ENV XDG_RUNTIME_DIR "/docker"
RUN $PKG_INSTALL shadow-uidmap fuse-overlayfs slirp4netns iproute2
RUN echo ${RUN_USER}:31072:65536 >> /etc/subuid
RUN echo ${RUN_USER}:31072:65536 >> /etc/subgid
RUN mkdir -p ${XDG_RUNTIME_DIR}
RUN ${ALLOW_USER} ${XDG_RUNTIME_DIR}
USER ${RUN_USER}
RUN wget -qO- https://get.docker.com/rootless | sed 's/curl .*-o /wget -qO/' | SKIP_IPTABLES=1 HOME=${XDG_RUNTIME_DIR} sh
USER root

FROM mwaeckerlin/scratch
ENV CONTAINERNAME "dockindock"
ENV XDG_RUNTIME_DIR "/docker"
ENV PATH "${XDG_RUNTIME_DIR}/bin:$PATH"
ENV DOCKER_HOST "unix://${XDG_RUNTIME_DIR}/docker.sock"
COPY --from=build / /
CMD HOME=${XDG_RUNTIME_DIR} ${XDG_RUNTIME_DIR}/bin/dockerd-rootless.sh
WORKDIR /home/${RUN_USER}
