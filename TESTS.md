# Tests

Register of all tests, grouped by kind and sorted by the [FEATURES.md](FEATURES.md) number each test covers. `npm test` runs everything; the guard `tests/docs-contract.sh` fails when a feature has no test entry here or when any test carries a skip/xfail marker — tests are never skipped.

## End-to-end

The suite starts a real privileged container and exercises it with `docker exec`.

- **F1** `tests/run-e2e.sh` › daemon_answers_docker_info — the rootless daemon comes up and answers `docker info`.
- **F2** `tests/run-e2e.sh` › inner_container_runs — an inner container is pulled and runs (`docker run --rm alpine` prints its marker).
- **F3** `tests/run-e2e.sh` › client_env_preconfigured — `docker version` succeeds with the shipped default environment.
- **F4** `tests/run-e2e.sh` › data_root_effective — the running daemon really stores under `/docker-data`.
- **F5** `tests/run-e2e.sh` › tcp_endpoint_reachable — a second daemon with `DOCKER_TCP_PORT` answers the API over the container network.
- **F7** `tests/run-e2e.sh` › daemon_options_applied — a daemon given `--registry-mirror` and `--insecure-registry` as its command lists the mirror in `docker info`.
- **F7** `tests/run-e2e.sh` › pull_through_mirror — a pull in that daemon succeeds and appears in the request log of the pull-through cache in the stack (docker falls back to Docker Hub silently, so the pull alone proves nothing).

## Image contract

- **F1** `tests/config-contract.sh` › rootless_launcher, subordinate_ids — dockerd-rootless.sh is shipped and the subordinate id ranges exist.
- **F1** `tests/config-contract.sh` › unprivileged_user — the default user is not root.
- **F3** `tests/config-contract.sh` › docker_client, docker_host_env — the client binary runs and `DOCKER_HOST` is preconfigured.
- **F4** `tests/config-contract.sh` › data_dir_writable — `/docker-data` exists and is writable for the daemon user.
- **F5** `tests/config-contract.sh` › invalid_tcp_port_rejected, invalid_data_root_rejected — malformed option values abort startup with a clear error (negative checks).
- **F7** `tests/config-contract.sh` › owned_data_root_option_rejected, owned_host_option_rejected — `--data-root` and `-H` given as options abort startup and name the setting to use instead (negative checks).
- **F7** `tests/config-contract.sh` › misspelt_option_stops_daemon — a misspelt option stops the daemon with an error naming the option (negative check).
- **F7** `tests/config-contract.sh` › command_runs_unchanged — a command that is no option runs unchanged, as images built on this one need.

## Workflow contract

- **F6** `tests/workflow-contract.sh` of `mwaeckerlin/scratch` — the reusable workflow selects exactly the images a repository publishes; this repository calls it from `.github/workflows/docker.yml`.
