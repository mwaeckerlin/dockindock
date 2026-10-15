#!/usr/bin/env bash
# Run the dockindock e2e suite: start the shipped image (privileged), wait
# for the rootless daemon, then prove docker-in-docker works end to end by
# running an inner container.
# Usage: bash tests/run-e2e.sh
set -uo pipefail

COMPOSE="tests/e2e/docker-compose.yml"
cd "$(dirname "$0")/.."

PASS=0
FAIL=0
declare -a FAILED_NAMES

_pass() { PASS=$((PASS + 1)); echo "  PASS  $1"; }
_fail() { FAIL=$((FAIL + 1)); FAILED_NAMES+=("$1"); echo "  FAIL  $1: $2"; }

cleanup() {
    docker compose -f "$COMPOSE" down -v --remove-orphans 2>/dev/null || true
}
trap cleanup EXIT

echo "==> Building test stack..."
docker compose -f "$COMPOSE" build --quiet

echo "==> Starting rootless docker daemons (privileged)..."
docker compose -f "$COMPOSE" up -d dockindock dind-tcp dind-mirror mirror

echo "==> Waiting for the daemon to answer..."
DEADLINE=$((SECONDS + 90))
READY=0
while [[ ${SECONDS} -lt ${DEADLINE} ]]; do
    if docker compose -f "$COMPOSE" exec -T dockindock docker info > /dev/null 2>&1; then
        READY=1
        break
    fi
    sleep 2
done
if [[ ${READY} -eq 1 ]]; then
    _pass "daemon_answers_docker_info"
else
    _fail "daemon_answers_docker_info" "docker info did not succeed within 90s"
    docker compose -f "$COMPOSE" logs --tail 50 dockindock
fi

if [[ ${READY} -eq 1 ]]; then
    if docker compose -f "$COMPOSE" exec -T dockindock docker version > /dev/null 2>&1; then
        _pass "client_env_preconfigured"
    else
        _fail "client_env_preconfigured" "docker version failed with default env"
    fi

    INNER=$(docker compose -f "$COMPOSE" exec -T dockindock docker run --rm alpine echo INNER-OK 2>&1)
    if echo "${INNER}" | grep -q "INNER-OK"; then
        _pass "inner_container_runs"
    else
        _fail "inner_container_runs" "inner docker run failed: ${INNER}"
    fi

    ROOTDIR=$(docker compose -f "$COMPOSE" exec -T dockindock docker info --format '{{.DockerRootDir}}' 2>&1)
    if echo "${ROOTDIR}" | grep -q "^/docker-data"; then
        _pass "data_root_effective"
    else
        _fail "data_root_effective" "daemon does not use /docker-data: ${ROOTDIR}"
    fi

    TCP_DEADLINE=$((SECONDS + 90))
    TCP_OK=0
    while [[ ${SECONDS} -lt ${TCP_DEADLINE} ]]; do
        TCPINFO=$(docker compose -f "$COMPOSE" exec -T -e DOCKER_HOST=tcp://dind-tcp:2375 dockindock docker info 2>&1)
        if echo "${TCPINFO}" | grep -q "Server Version"; then
            TCP_OK=1
            break
        fi
        sleep 2
    done
    if [[ ${TCP_OK} -eq 1 ]]; then
        _pass "tcp_endpoint_reachable"
    else
        _fail "tcp_endpoint_reachable" "TCP API not reachable: ${TCPINFO}"
    fi
fi

# dind-mirror gets its daemon options as the compose command; the daemon
# must know the mirror, and a pull must reach the mirror — docker falls back
# to Docker Hub silently when a mirror fails, so a successful pull alone
# proves nothing and the mirror's own request log is the evidence
MIRROR_DEADLINE=$((SECONDS + 90))
MIRRORS=""
while [[ ${SECONDS} -lt ${MIRROR_DEADLINE} ]]; do
    MIRRORS=$(docker compose -f "$COMPOSE" exec -T dind-mirror docker info --format '{{json .RegistryConfig.Mirrors}}' 2>&1)
    if [[ $? -eq 0 ]]; then
        break
    fi
    sleep 2
done
if echo "${MIRRORS}" | grep -q '"http://mirror:5000/"'; then
    _pass "daemon_options_applied"
else
    _fail "daemon_options_applied" "inner daemon does not list the mirror: ${MIRRORS}"
    docker compose -f "$COMPOSE" logs --tail 50 dind-mirror
fi

PULL=$(docker compose -f "$COMPOSE" exec -T dind-mirror docker pull alpine 2>&1)
MIRROR_LOG=$(docker compose -f "$COMPOSE" logs mirror 2>&1)
if echo "${PULL}" | grep -q "docker.io/library/alpine" && echo "${MIRROR_LOG}" | grep -q "/v2/library/alpine/manifests/"; then
    _pass "pull_through_mirror"
else
    _fail "pull_through_mirror" "pull did not go through the mirror: ${PULL}"
fi

echo ""
echo "==> E2E results: ${PASS} passed, ${FAIL} failed"
if [[ ${FAIL} -gt 0 ]]; then
    echo "==> Failed: ${FAILED_NAMES[*]}"
    echo "==> Collecting logs on failure..."
    docker compose -f "$COMPOSE" logs --tail 60 dockindock dind-tcp dind-mirror mirror
    exit 1
fi
