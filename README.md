# dockindock
Docker image to run docker in docker.

Note: The image must be started with option ```--privileged```

Build:
```
docker build --rm --force-rm -t dockindock
```

Run:
  1. run the docker container that contains sub docker containers:
     ```
     docker run run -d --privileged --name dockindock dockindock
     ```
  2. run the a mysql container within the parent docker container:
     ```
     docker exec dockindock docker run --name mysql-test -e MYSQL_ROOT_PASSWORD=... mysql
     ```
  3. stop and remove the a mysql container, then stop and remove the parent docker container:
     ```
     docker exec dockindock docker stop mysql-test
     docker exec dockindock docker rm mysql-test
     docker stop dockindock
     docker rm dockindock
     ```
