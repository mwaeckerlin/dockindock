Docker in Docker
================

Docker image to run docker in docker. Use mwaeckerlin/reverse-proxy
for reverse proxy to forward requests from outside do contained docker
instances.

Note: The image must be started with option `--privileged`

Build:

    docker build --rm --force-rm -t mwaeckerlin/dockindock .

Run:
  1. run the docker container that contains sub docker containers:

        docker run -d --privileged --name dockindock -p 80:80 mwaeckerlin/dockindock
  2. run a mysql container within the parent docker container:

        docker exec dockindock docker run -d --name mysql-test -e MYSQL_ROOT_PASSWORD=$(pwgen -s 16 1) mysql
  3. run a wordpress container within the parent docker container:

        docker exec dockindock docker run -d --name wordpress-test --link mysql-test:mysql wordpress
  4. run a reverse-proxy container to forward port 80 of reverse-proxy to port 80 of wordpress:

        docker exec dockindock docker run -d --name reverse-proxy --link wordpress-test:test.mydomain.com -p 80:80 mwaeckerlin/reverse-proxy
  5. setup your DNS or add `test.mydomain.com` to `127.0.0.1` in your host's `/etc/hosts`
  6. enter url in your browser on docker host: `http://test.mydomain.com`
  7. stop and remove the inner containers (optional), then stop and remove the parent container:
     (Please note that all inner containers are lost when you remove the parent container)

        docker exec dockindock docker stop mysql-test wordpress-test reverse-proxy
        docker exec dockindock docker rm mysql-test wordpress-test reverse-proxy
        docker stop dockindock
        docker rm dockindock
