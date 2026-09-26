# Tests

Register of all tests, grouped by kind and sorted by the [FEATURES.md](FEATURES.md) number each test covers. `npm test` runs everything; the guard `tests/docs-contract.sh` fails when a feature has no test entry here or when any test carries a skip/xfail marker — tests are never skipped.

## End-to-end

The suite starts a real privileged container and exercises it with `docker exec`.

- **F1** `tests/run-e2e.sh` › daemon_answers_docker_info — the rootless daemon comes up and answers `docker info`.
- **F2** `tests/run-e2e.sh` › inner_container_runs — an inner container is pulled and runs (`docker run --rm alpine` prints its marker).
- **F3** `tests/run-e2e.sh` › client_env_preconfigured — `docker version` succeeds with the shipped default environment.
- **F4** `tests/run-e2e.sh` › data_root_effective — the running daemon really stores under `/docker-data`.
- **F5** `tests/run-e2e.sh` › tcp_endpoint_reachable — a second daemon with `DOCKER_TCP_PORT` answers the API over the container network.

## Image contract

- **F1** `tests/config-contract.sh` › rootless_launcher, subordinate_ids — dockerd-rootless.sh is shipped and the subordinate id ranges exist.
- **F1** `tests/config-contract.sh` › unprivileged_user — the default user is not root.
- **F3** `tests/config-contract.sh` › docker_client, docker_host_env — the client binary runs and `DOCKER_HOST` is preconfigured.
- **F4** `tests/config-contract.sh` › data_dir_writable — `/docker-data` exists and is writable for the daemon user.
- **F5** `tests/config-contract.sh` › invalid_tcp_port_rejected, invalid_data_root_rejected — malformed option values abort startup with a clear error (negative checks).

## Workflow contract

- **F6** `tests/workflow-contract.sh` of `mwaeckerlin/scratch` — the reusable workflow selects exactly the images a repository publishes; this repository calls it from `.github/workflows/docker.yml`.
