FROM mwaeckerlin/very-base AS build
ENV XDG_RUNTIME_DIR="/docker"
RUN $PKG_INSTALL shadow-uidmap fuse-overlayfs slirp4netns iproute2 iptables ip6tables libcap-setcap libcap-getcap
RUN echo ${RUN_USER}:31072:65536 >> /etc/subuid
RUN echo ${RUN_USER}:31072:65536 >> /etc/subgid
RUN mkdir -p ${XDG_RUNTIME_DIR}
RUN ${ALLOW_USER} ${XDG_RUNTIME_DIR}
# separate data directory: persistence volumes mount here, never on
# ${XDG_RUNTIME_DIR} (that would mask the toolchain with stale binaries)
RUN mkdir -p /docker-data
RUN ${ALLOW_USER} /docker-data
USER ${RUN_USER}
# SKIP_IPTABLES only skips the installer's build-host kernel-module check
# (iptables itself is installed above); the exec_setuptool call is removed
# because it starts rootlesskit — impossible inside a build container (no
# user namespaces). Only the downloaded binaries are needed here, the
# daemon function is verified at runtime by tests/run-e2e.sh
RUN wget -qO- https://get.docker.com/rootless | sed -e 's/curl .*-o /wget -qO/' -e 's/^[[:space:]]*exec_setuptool .*/true/' | SKIP_IPTABLES=1 HOME=${XDG_RUNTIME_DIR} sh
USER root

FROM mwaeckerlin/scratch
ENV CONTAINERNAME="dockindock"
ENV XDG_RUNTIME_DIR="/docker"
# ${XDG_RUNTIME_DIR}/bin holds the rootless docker toolchain; it precedes the
# system paths deliberately — the binaries exist nowhere else, and the whole
# directory belongs to the same unprivileged user the daemon runs as
ENV PATH="${XDG_RUNTIME_DIR}/bin:$PATH"
ENV DOCKER_HOST="unix://${XDG_RUNTIME_DIR}/docker.sock"
ENV DOCKER_DATA_ROOT="/docker-data"
ENV DOCKER_TCP_PORT=""
COPY --from=build / /
ADD --chmod=755 files/entrypoint.sh /entrypoint.sh
USER root
# CAP_SYS_ADMIN file capability on the rootlesskit supervisor: current
# Ubuntu hosts block user-namespace creation for capability-less processes
# (kernel.apparmor_restrict_unprivileged_userns) — the capability is the
# documented exemption and keeps the image independent of any host
# AppArmor/sysctl configuration. Only the small supervisor carries it
# (inside an already privileged container); the daemon and all workloads
# still run as the unprivileged user. Set in the final stage so it is
# guaranteed to survive into the shipped image.
RUN setcap cap_sys_admin+ep ${XDG_RUNTIME_DIR}/bin/rootlesskit
USER ${RUN_USER}
CMD ["/entrypoint.sh"]
WORKDIR /home/${RUN_USER}
