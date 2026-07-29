#!/bin/sh -e
# Start the rootless docker daemon.
#
# DOCKER_DATA_ROOT  image/container storage — mount a named volume here for
#                   persistence (never on /docker: that would mask the
#                   toolchain with stale binaries).
# DOCKER_TCP_PORT   when set, additionally listen on tcp://0.0.0.0:<port>.
#                   The daemon process runs in the container's network
#                   namespace (only container networking lives in the
#                   detached netns), so the listener is directly reachable
#                   from the container network. Plain TCP without TLS —
#                   see the README trade-off; keep the port on an isolated
#                   container network.
#
# Both values reach exec/flags, so they are whitelist-checked: a typo must
# abort with a clear error, never start a daemon with surprise flags.
case "${DOCKER_DATA_ROOT}" in
  ''|*[!A-Za-z0-9/._-]*) echo "invalid DOCKER_DATA_ROOT: '${DOCKER_DATA_ROOT}'" >&2; exit 1 ;;
esac
if [ -n "${DOCKER_TCP_PORT}" ]; then
  case "${DOCKER_TCP_PORT}" in
    *[!0-9]*) echo "invalid DOCKER_TCP_PORT: '${DOCKER_TCP_PORT}'" >&2; exit 1 ;;
  esac
fi

export HOME="${XDG_RUNTIME_DIR}"
set -- --data-root "${DOCKER_DATA_ROOT}"
if [ -n "${DOCKER_TCP_PORT}" ]; then
  # --tls=false declares the plain-TCP endpoint as intentional: without it
  # dockerd delays startup by 15s today and refuses to start in a future
  # release (the port belongs on an isolated network, see README)
  set -- "$@" -H "unix://${XDG_RUNTIME_DIR}/docker.sock" -H "tcp://0.0.0.0:${DOCKER_TCP_PORT}" --tls=false
fi
exec "${XDG_RUNTIME_DIR}/bin/dockerd-rootless.sh" "$@"
