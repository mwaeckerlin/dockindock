# Rootless Docker in Docker

[mwaeckerlin/dockindock] runs a complete docker daemon inside a container — as an unprivileged user. Use it for CI jobs, sandboxes and nested tooling that need their own isolated docker without handing them root.

Unlike classic docker-in-docker images, the inner daemon runs rootless: even a full compromise of the inner docker never yields a root process inside the container. The docker CLI is preconfigured (`DOCKER_HOST`, `PATH`), so `docker …` works out of the box.

All features are listed in [FEATURES.md](FEATURES.md), all tests in [TESTS.md](TESTS.md).

The image is self-contained: it needs no host configuration (no AppArmor profile, no sysctl change) — current Ubuntu hosts restrict user-namespace creation for capability-less processes, and the image answers that with a `CAP_SYS_ADMIN` file capability on the small rootlesskit supervisor (see the trade-off below).

## Usage

The container must be started with `--privileged` (rootless docker needs the namespace and mount privileges), with a named volume on `/docker-data`:

    docker run -d --privileged -v dockindock-data:/docker-data --name dockindock mwaeckerlin/dockindock

Or with the bundled compose file:

- `npm run build`
- `npm start` (foreground) or `npm run start:daemon` (background)
- run a container inside: `docker compose exec dockindock docker run --rm alpine echo hello`
- stop with `Ctrl+C` (or `npm stop` for daemon mode)

## Configuration

- **`DOCKER_DATA_ROOT`** (default `/docker-data`) — where the inner daemon stores images and containers. **Always mount a named volume on `/docker-data`**: besides persistence, the inner overlay mounts cannot sit on the container's own overlayfs (the kernel rejects overlay-on-overlay). Never mount over `/docker` (that would mask the toolchain).
- **`DOCKER_TCP_PORT`** (default: unset) — when set (e.g. `2375`), the docker API is additionally published on `tcp://0.0.0.0:<port>`, so the container can serve as a shared docker-in-docker service for sibling containers that point `DOCKER_HOST=tcp://<service>:<port>` at it. Malformed values abort startup with a clear error.
- **Additional daemon options** — when the first argument of the container command starts with `-`, all arguments go to the inner `dockerd`, after the image's own options. A registry mirror, so the inner daemon does not pull from Docker Hub anonymously:

  ```sh
  docker run -d --privileged -v dockindock-data:/docker-data mwaeckerlin/dockindock \
      --registry-mirror=http://dockerhub-cache:5000 \
      --insecure-registry=dockerhub-cache:5000
  ```

  In a compose file the same options stand under `command:`. Storage and listeners stay with `DOCKER_DATA_ROOT` and `DOCKER_TCP_PORT`: `--data-root`, `-H` and `--host` as options abort startup. A command whose first argument does not start with `-` runs instead of the daemon, unchanged.

The daemon runs as `somebody` (uid 100, gid 1000), and the inner containers use the subordinate ids 31072 to 96607. A host directory mounted on `/docker-data` belongs to uid 100.

## Security Trade-Offs

- **`--privileged` is required**: the flag grants the container broad access to the host — run the image only on hosts where that is acceptable. Inside the container, everything still runs as an unprivileged user (rootless daemon).
- **The rootlesskit supervisor carries a `CAP_SYS_ADMIN` file capability**: current Ubuntu hosts block user-namespace creation for capability-less processes; the capability is the documented exemption and keeps the image independent of any host configuration. Only the small supervisor gains it — inside a container that must be `--privileged` anyway — while the daemon and every workload keep running as the unprivileged user.
- **The toolchain directory `/docker/bin` precedes the system `PATH`**: the rootless binaries exist nowhere else, and the directory belongs to the same unprivileged user the daemon runs as — a process able to write there already runs as that user, so nothing is gained by shadowing.
- **The optional TCP endpoint is plain, unauthenticated TCP**: anyone who can reach the port controls the inner daemon. Because the daemon is rootless, that grants at most the unprivileged daemon user — still, only enable `DOCKER_TCP_PORT` on an isolated container network dedicated to the consumers (as the hermes and openclaw stacks do), never publish it to a host port or a shared network.

## Tests

`npm test` runs the docs contract (every feature in [FEATURES.md](FEATURES.md) has a test in [TESTS.md](TESTS.md), no skipped tests), the config contract (client, rootless launcher, subordinate ids, unprivileged user, preconfigured environment, rejected and misspelt options, a command that runs unchanged) and the end to end suite, which starts the daemon privileged, runs a real inner container and pulls through a registry mirror given as daemon options:

    npm test            # docs + config contract + e2e

## Development

The image is built from [mwaeckerlin/very-base] (build stage) and ships on [mwaeckerlin/scratch]; the rootless toolchain is installed by the official `get.docker.com/rootless` script into `/docker`.

[mwaeckerlin/dockindock]: https://hub.docker.com/r/mwaeckerlin/dockindock "get the image from docker hub"
[mwaeckerlin/very-base]: https://github.com/mwaeckerlin/very-base "build-only base image, never for production"
[mwaeckerlin/scratch]: https://github.com/mwaeckerlin/scratch "minimalistic runtime base image"
