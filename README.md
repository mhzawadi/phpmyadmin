# phpMyAdmin Docker image

Run phpMyAdmin with Alpine, nginx and PHP FPM.

![GitHub Repo stars](https://img.shields.io/github/stars/mhzawadi/phpmyadmin?style=social)
[![Latest image](https://github.com/mhzawadi/phpmyadmin/actions/workflows/image-latest.yml/badge.svg)](https://github.com/mhzawadi/phpmyadmin/actions/workflows/image-latest.yml)
![Docker Pulls](https://img.shields.io/docker/pulls/mhzawadi/phpmyadmin.svg)
![Docker Stars](https://img.shields.io/docker/stars/mhzawadi/phpmyadmin.svg)

All following examples will bring you phpMyAdmin on `http://localhost:8080`
where you can enjoy your happy MySQL administration.

## Credentials

phpMyAdmin does use MySQL server credential, please check the corresponding
server image for information how it is setup.

The official MySQL and MariaDB use following environment variables to define these:

* `MYSQL_ROOT_PASSWORD` - This variable is mandatory and specifies the password that will be set for the `root` superuser account.
* `MYSQL_USER`, `MYSQL_PASSWORD` - These variables are optional, used in conjunction to create a new user and to set that user's password.

## Docker hub tags

You can use following tags on Docker hub:

* `latest` - latest stable release
* `4.8` - latest stable release for the 4.8 version
* `edge` - bleeding edge docker image (contains stable phpMyAdmin, but the Docker image changes might not yet be fully tested)
* `edge-4.8` - bleeding edge docker image + latest snapshots from 4.8 branch (currently master)

## Usage with linked server

### Mysql

Run a MySQL database, dedicated to phpmyadmin

```bash
docker run --name phpmyadmin-mysql -e MYSQL_ROOT_PASSWORD=my-secret-pw -v /my_dir/phpmyadmin:/var/lib/mysql -d mysql:5.7
```

Here, we store data on the host system under `/my_dir/phpmyadmin` and use a specific root password.

### phpMyAdmin
The below command will start phpmyadmin on port 8080:

```
docker run --name myadmin -d --link phpmyadmin-mysql:db -p 8080:80 mhzawadi/phpmyadmin
```

## Usage with external server

You can specify MySQL host in the `PMA_HOST` environment variable. You can also
use `PMA_PORT` to specify port of the server in case it's not the default one:

```
docker run --name myadmin -d -e PMA_HOST=dbhost -p 8080:80 mhzawadi/phpmyadmin
```

## Usage with arbitrary server

You can use arbitrary servers by adding ENV variable `PMA_ARBITRARY=1` to the startup command:

```
docker run --name myadmin -d -e PMA_ARBITRARY=1 -p 8080:80 mhzawadi/phpmyadmin
```

## Usage with docker-compose and arbitrary server

This will run phpMyAdmin with arbitrary server - allowing you to specify MySQL/MariaDB
server on login page.

Using the docker-compose.yml from https://github.com/phpmyadmin/docker

```
docker-compose up -d
```

## Run the E2E tests with docker-compose

You can run the E2E tests with the local test environment by running MariaDB/MySQL databases. Adding ENV variable `PHPMYADMIN_RUN_TEST=true` already added on docker-compose file. Simply run:

Using the docker-compose.testing.yml from https://github.com/phpmyadmin/docker

```
docker-compose -f docker-compose.testing.yml up phpmyadmin
```

## Adding Custom Configuration

You can add your own custom config.inc.php settings (such as Configuration Storage setup)
by creating a file named "config.user.inc.php" with the various user defined settings
in it, and then linking it into the container using:

```
-v /some/local/directory/config.user.inc.php:/etc/phpmyadmin/config.user.inc.php
```
On the "docker run" line like this:
```
docker run --name myadmin -d --link mysql_db_server:db -p 8080:80 -v /some/local/directory/config.user.inc.php:/etc/phpmyadmin/config.user.inc.php mhzawadi/phpmyadmin
```

See the following links for config file information.
https://docs.phpmyadmin.net/en/latest/config.html#config
https://docs.phpmyadmin.net/en/latest/setup.html

## Usage behind reverse proxys

Set the variable ``PMA_ABSOLUTE_URI`` to the fully-qualified path (``https://pma.example.net/``) where the reverse proxy makes phpMyAdmin available.

## Environment variables summary

* ``PMA_ARBITRARY`` - when set to 1 connection to the arbitrary server will be allowed
* ``PMA_HOST`` - define address/host name of the MySQL server
* ``PMA_VERBOSE`` - define verbose name of the MySQL server
* ``PMA_PORT`` - define port of the MySQL server
* ``PMA_HOSTS`` - define comma separated list of address/host names of the MySQL servers
* ``PMA_VERBOSES`` - define comma separated list of verbose names of the MySQL servers
* ``PMA_PORTS`` - define comma separated list of ports of the MySQL servers
* ``PMA_USER`` and ``PMA_PASSWORD`` - define username to use for config authentication method
* ``PMA_ABSOLUTE_URI`` - define user-facing URI

For more detailed documentation see https://docs.phpmyadmin.net/en/latest/setup.html#installing-using-docker

[hub]: https://hub.docker.com/r/mhzawadi/phpmyadmin/

Please report any issues with the Docker container to https://github.com/phpmyadmin/docker/issues

### how to build
Latest is build from the docker hub once I push to the github repo, the arm versions are built from my mac with the below buildx tool

`docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 -t mhzawadi/phpmyadmin:v5.1.1.1 --push .`
