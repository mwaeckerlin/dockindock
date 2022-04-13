Docker in Docker
================

Docker image to run docker in docker. Use mwaeckerlin/reverse-proxy
for reverse proxy to forward requests from outside do contained docker
instances.

Note: The image must be started with option `--privileged`.

Be aware: With `--priviledged` you gain access to upper layer operation system.

Run:

      docker-compose up

Run docker container in docker container:

     docker-compose exec dockindock docker run --rm -it mwaeckerlin/very-base