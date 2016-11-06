# A Swagger UI running inside docker.

A Docker container for setting up Swagger UI. This server provides documentation for the API.

Swagger is an open-source documentation tool.

This container best suites development purposes.

This is a sample Swagger docker container used to test GFB's installation on [http://www.globalfoodbook.com](http://www.globalfoodbook.com)


To build this swagger server run the following command:

```bash
$ docker pull globalfoodbook/swagger
```

This will run on a internal default port of 80.

To run the server on the host machine, run the following command:

```bash
$ docker run --name=swagger --detach=true swagger

```

# NB:

## Before pushing to docker hub

## Login

```bash
$ docker login
```

## Build

```bash
$ cd /to/docker/directory/path/
$ docker build -t <username>/<repo>:latest .
```

## Push to docker hub

```bash
$ docker push <username>/<repo>:latest
```


IP=`docker inspect swagger | grep -w "IPAddress" | awk '{ print $2 }' | head -n 1 | cut -d "," -f1 | sed "s/\"//g"`
HOST_IP=`/sbin/ifconfig eth1 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`

DOCKER_HOST_IP=`awk 'NR==1 {print $1}' /etc/hosts` # from inside a docker container
