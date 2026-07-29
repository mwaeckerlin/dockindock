# Changelog

- 2026-07-28 **1.0.0**
    - Image updated to the current base images and the current rootless docker release after four years without maintenance
        - rebuilding on the current base also fixes derived images that merge this image with other current images (file type conflicts such as `/var/lock` no longer occur)
    - Port publishing works out of the box: the packet filter tools are now included in the image
    - New: persistent storage in a dedicated data directory (always mount a named volume on `/docker-data` — it also keeps the inner overlay mounts off the container's own overlayfs) without ever masking the toolchain
    - New: optional network endpoint (`DOCKER_TCP_PORT`) so the image can serve as a shared docker-in-docker service for sibling containers (used by the hermes and openclaw stacks); malformed option values abort startup with a clear error
    - No host configuration needed: current Ubuntu hosts block user-namespace creation for capability-less processes — the rootlesskit supervisor now carries the documented capability exemption inside the image, so neither an AppArmor profile nor a sysctl change is required on the host (trade-off in the README)
    - Test suite added: contract checks (client, rootless launcher, subordinate ids, unprivileged user, preconfigured environment) and an end to end test that starts the daemon and runs a real inner container
    - Feature and test registers added (FEATURES.md, TESTS.md) with an automatic guard: every feature must have a test, and no test may be skipped
    - Standard build and test commands added (`npm run build`, `npm test`)
