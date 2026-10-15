#!/bin/sh -e
# Start the rootless docker daemon.
#
# Arguments follow the convention of the official docker:dind image: when
# the first one is an option (starts with "-"), all of them are additional
# options of the inner daemon, appended after the image's own; otherwise
# they are a command that runs unchanged (derived images start the daemon
# from a CMD of their own).
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
case "${1}" in
  ''|-*) ;;
  *) exec "$@" ;;
esac
# the storage and the listeners have one source each, the variables above;
# the same option given again as an argument would silently win over them
for option in "$@"; do
  case "${option}" in
    --data-root|--data-root=*) echo "invalid daemon option '${option}': set DOCKER_DATA_ROOT instead" >&2; exit 1 ;;
    -H|-H?*|--host|--host=*) echo "invalid daemon option '${option}': set DOCKER_TCP_PORT instead" >&2; exit 1 ;;
  esac
done
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
# the image's own options go in front of the additional ones, which keep
# their order and quoting; the daemon itself refuses an unknown option by
# name and stops
set -- --data-root "${DOCKER_DATA_ROOT}" "$@"
if [ -n "${DOCKER_TCP_PORT}" ]; then
  # --tls=false declares the plain-TCP endpoint as intentional: without it
  # dockerd delays startup by 15s today and refuses to start in a future
  # release (the port belongs on an isolated network, see README)
  set -- -H "unix://${XDG_RUNTIME_DIR}/docker.sock" -H "tcp://0.0.0.0:${DOCKER_TCP_PORT}" --tls=false "$@"
fi
exec "${XDG_RUNTIME_DIR}/bin/dockerd-rootless.sh" "$@"
