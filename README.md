# Rootless Docker in Docker

Docker image to run docker in docker as non root user.

Note: The image must be started with option `--privileged`.

Be aware: With `--privileged` you gain access to upper layer operation system.

Run:

      docker-compose up --build

Run docker container in docker container:

     docker-compose exec dockindock docker run --rm -it mwaeckerlin/very-base