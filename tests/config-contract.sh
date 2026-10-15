#!/usr/bin/env bash
# Config contract: the shipped image must carry a working rootless docker
# toolchain for the unprivileged default user.
#
# The checks run the shipped binaries themselves (no daemon needed):
#   docker --version   proves the client is present and executable,
#   dockerd-rootless.sh and the subordinate id ranges prove the daemon can
#   be started rootless, and the default user must be unprivileged.
# `--pull=never` keeps docker from silently pulling a stale image from the
# registry when the local build is missing; that would test the wrong
# artefact.
#
# Usage: tests/config-contract.sh IMAGE

set -uo pipefail

IMAGE="${1:?usage: tests/config-contract.sh IMAGE}"

PASS=0
FAIL=0
declare -a FAILED_NAMES

_pass() { PASS=$((PASS + 1)); echo "  PASS  $1"; }
_fail() { FAIL=$((FAIL + 1)); FAILED_NAMES+=("$1"); echo "  FAIL  $1: $2"; }

echo "==> Config contract: rootless docker toolchain"

if ! docker image inspect "${IMAGE}" > /dev/null 2>&1; then
    _fail "${IMAGE}_image_exists" "image not built — run 'npm run build' first"
else
    if docker run --rm --pull=never --entrypoint /docker/bin/docker "${IMAGE}" --version > /dev/null 2>&1; then
        _pass "${IMAGE}_docker_client"
    else
        _fail "${IMAGE}_docker_client" "/docker/bin/docker missing or not executable"
    fi

    if docker run --rm --pull=never --entrypoint /bin/sh "${IMAGE}" -c 'test -x /docker/bin/dockerd-rootless.sh' > /dev/null 2>&1; then
        _pass "${IMAGE}_rootless_launcher"
    else
        _fail "${IMAGE}_rootless_launcher" "dockerd-rootless.sh missing"
    fi

    if docker run --rm --pull=never --entrypoint /bin/sh "${IMAGE}" -c 'grep -q ":31072:65536" /etc/subuid && grep -q ":31072:65536" /etc/subgid' > /dev/null 2>&1; then
        _pass "${IMAGE}_subordinate_ids"
    else
        _fail "${IMAGE}_subordinate_ids" "subuid/subgid ranges missing"
    fi

    USER_OUT=$(docker run --rm --pull=never --entrypoint /usr/bin/whoami "${IMAGE}" 2>&1)
    if [[ "${USER_OUT}" != "root" && -n "${USER_OUT}" ]]; then
        _pass "${IMAGE}_unprivileged_user"
    else
        _fail "${IMAGE}_unprivileged_user" "default user is '${USER_OUT}'"
    fi

    ENV_OUT=$(docker image inspect --format '{{.Config.Env}}' "${IMAGE}" 2>&1)
    if echo "${ENV_OUT}" | grep -q 'DOCKER_HOST=unix:///docker/docker.sock'; then
        _pass "${IMAGE}_docker_host_env"
    else
        _fail "${IMAGE}_docker_host_env" "DOCKER_HOST not preconfigured: ${ENV_OUT}"
    fi

    # the dedicated data directory must be writable for the daemon user
    if docker run --rm --pull=never --entrypoint /bin/sh "${IMAGE}" -c 'test -d /docker-data && test -w /docker-data' > /dev/null 2>&1; then
        _pass "${IMAGE}_data_dir_writable"
    else
        _fail "${IMAGE}_data_dir_writable" "/docker-data missing or not writable for the daemon user"
    fi

    # negative: operator input reaching exec/flags must be whitelist-checked
    OUT=$(docker run --rm --pull=never -e DOCKER_TCP_PORT=23x5 "${IMAGE}" 2>&1)
    if [[ $? -ne 0 && "${OUT}" == *"invalid DOCKER_TCP_PORT"* ]]; then
        _pass "${IMAGE}_invalid_tcp_port_rejected"
    else
        _fail "${IMAGE}_invalid_tcp_port_rejected" "bad port not rejected: ${OUT}"
    fi
    OUT=$(docker run --rm --pull=never -e 'DOCKER_DATA_ROOT=/x;reboot' "${IMAGE}" 2>&1)
    if [[ $? -ne 0 && "${OUT}" == *"invalid DOCKER_DATA_ROOT"* ]]; then
        _pass "${IMAGE}_invalid_data_root_rejected"
    else
        _fail "${IMAGE}_invalid_data_root_rejected" "bad data root not rejected: ${OUT}"
    fi

    # additional daemon options come as the command; the options the image
    # sets from its own variables must not be given a second way
    OUT=$(docker run --rm --pull=never "${IMAGE}" --data-root=/elsewhere 2>&1)
    if [[ $? -ne 0 && "${OUT}" == *"set DOCKER_DATA_ROOT instead"* ]]; then
        _pass "${IMAGE}_owned_data_root_option_rejected"
    else
        _fail "${IMAGE}_owned_data_root_option_rejected" "--data-root not rejected: ${OUT}"
    fi
    OUT=$(docker run --rm --pull=never "${IMAGE}" -H tcp://0.0.0.0:2376 2>&1)
    if [[ $? -ne 0 && "${OUT}" == *"set DOCKER_TCP_PORT instead"* ]]; then
        _pass "${IMAGE}_owned_host_option_rejected"
    else
        _fail "${IMAGE}_owned_host_option_rejected" "-H not rejected: ${OUT}"
    fi
    # a misspelt option reaches the daemon, which refuses it by name and stops
    OUT=$(docker run --rm --pull=never --privileged "${IMAGE}" --registry-mirrror=http://mirror:5000 2>&1)
    if [[ $? -ne 0 && "${OUT}" == *"unknown flag: --registry-mirrror"* ]]; then
        _pass "${IMAGE}_misspelt_option_stops_daemon"
    else
        _fail "${IMAGE}_misspelt_option_stops_daemon" "misspelt option not refused: ${OUT}"
    fi
    # a command that is no option runs unchanged, as before: derived images
    # (mwaeckerlin/vscode) start the daemon from a CMD of their own
    OUT=$(docker run --rm --pull=never "${IMAGE}" /bin/sh -c 'echo COMMAND-OK' 2>&1)
    if [[ "${OUT}" == "COMMAND-OK" ]]; then
        _pass "${IMAGE}_command_runs_unchanged"
    else
        _fail "${IMAGE}_command_runs_unchanged" "command not run as given: ${OUT}"
    fi
fi

echo ""
echo "==> Config contract results: ${PASS} passed, ${FAIL} failed"
if [[ ${FAIL} -gt 0 ]]; then
    echo "==> Failed contracts: ${FAILED_NAMES[*]}"
    exit 1
fi
