# tiddlywiki-docker

[TiddlyWiki 5](https://tiddlywiki.com) Docker image.

## Supported Tags

* `5.3.1`, `5.3.1-node20.9-alpine3.17`, `latest`
* `5.2.2`, `5.2.2-node17.9-alpine3.15` (via nicolaw/tiddlywiki)
* `5.2.0`, `5.2.0-node17.0-alpine3.13` (via nicolaw/tiddlywiki)
* `5.1.23`, `5.1.23-node14.18.1-alpine3.14` (via nicolaw/tiddlywiki)
* `5.1.22`, `5.1.22-node14.9.0-alpine3.12` (via nicolaw/tiddlywiki)

## Requirements

1. Install Docker. See https://docs.docker.com/install/ for help. For lazy and
   non-security minded Linux users, simply run the following command:
   `curl -fsSL get.docker.com | sudo bash`

2. If you want to automatically start TiddlyWiki on boot, you will need to be
   running a recent Linux distribution that uses systemd. (Ubuntu 12 or older,
   for example, do not support systemd by default).

## Manual Execution

```console
$ docker run -p 8080:8080 --name mywiki elquimista/tiddlywiki
```

Open your browser to http://localhost:8080 to access the TiddlyWiki.

Alternatively the following will instruct Docker to keep your TiddlyWiki
container running at all times untill explicitly stopped with a `docker stop` or
`docker kill` command:

```console
$ mkdir ~/tiddlywiki
$ docker run \
    -p 8080:8080 -d --restart unless-stopped --name mywiki \
    -v ~/tiddlywiki:/var/lib/tiddlywiki \
    elquimista/tiddlywiki
```

## Systemd Service

A systemd service unit file is included in the source repository of this
project. (See https://gitlab.com/nicolaw/tiddlywiki). This can be installed to
automatically start one or more TiddlyWikis every time your machine boots.

It also provides you with some level of configurability by simply changing the
contents of the `/etc/tiddlywiki/mywiki.conf` configuration file.

```console
$ sudo mkdir /etc/tiddlywiki/
$ sudo cp tiddlywiki.service /etc/systemd/system/mywiki.service
$ sudo cp tiddlywiki.conf /etc/tiddlywiki/mywiki.conf
$ sudo systemctl daemon-reload
$ sudo systemctl start mywiki.service
```

Check the status of the TiddlyWiki service, or watch the logs using the
following commands:

```console
$ sudo systemctl status mywiki.service
$ sudo journalctl -f -u mywiki.service
```

## Tiddler Data Storage

The container stores the Tiddler data in `/var/lib/tiddlywiki`. This will
automatically be saved inside an anonymous Docker volume.

Specifying a volume bind mount location for `/var/lib/tiddlywiki` will cause the
Tiddler data to be written to that location on your local filesystem.

```console
$ docker run --rm -p 8080:8080 -v ~/wikidata:/var/lib/tiddlywiki --name mywiki elquimista/tiddlywiki
```

In the case of operating TiddlyWiki from systemd, the Docker volume has the
same name as the systemd service name (`mywiki.service` by default). Use
`docker volume inspect mywiki.service` see where your data is being stored
on disk in the event that you wish to perform a backup.

Alternatively, to specify a bind mount location, uncomment and modify the
`TW_DOCKERVOLUME` line, and optionally the `TW_DOCKERUID` and `TW_DOCKERGID`
lines in the `/etc/tiddlywiki/mywiki.conf` configuration file.

You will need to restart the service once you have saved your file change.

```console
$ sudo vi /etc/tiddlywiki/mywiki.conf
$ sudo systemctl restart mywiki.service
```

## Authentication

By default, the username is set to `anonymous` with no password.

Specify the `TW_USERNAME` and `TW_PASSWORD` environment variables to enable
password authentication.

```console
$ docker run -p 8080:8080 -e "TW_USERNAME=$USER" -e "TW_PASSWORD=hunter2" --name mywiki elquimista/tiddlywiki
```

Similarly if you are using systemd to start your TiddlyWiki, uncomment and
modify the `TW_USERNAME` and `TW_PASSWORD` lines from the
`/etc/tiddlywiki/mywiki.conf` file.

You will need to restart the service once you have saved your file change.

```console
$ sudo vi /etc/tiddlywiki/mywiki.conf
$ sudo systemctl restart mywiki.service
```

## Configurable Variables

Refer to the canonical online documentation for help for additional help.

* https://tiddlywiki.com/static/Using%2520TiddlyWiki%2520on%2520Node.js.html
* https://tiddlywiki.com/static/ServerCommand.html

```ini
TW_WIKINAME=mywiki
TW_USERNAME=janedoe
TW_PASSWORD=
TW_PORT=8080
TW_ROOTTIDDLER=$:/core/save/all
TW_RENDERTYPE=text/plain
TW_SERVETYPE=text/html
TW_HOST=0.0.0.0
TW_PATHPREFIX=
```

You can alter how the NodeJS tiddlywiki server will operate by changing these
two variables.

If you are operating in a low memory environment (inside a small
AWS, GCE or other cloud virtual machine for example), you may wish to set
`NODE_MEM` to specify the maximum memory can NodeJS may use (specified in MB).

```ini
NODE_MEM=400
NODE_OPTIONS=
```

The following variables only affect the operation while using the system service
unit to start TiddlyWiki. They do nothing if you are running the Docker
container independently of systemd.

```ini
TW_DOCKERVOLUME=/home/janedoe/tiddlywiki
TW_DOCKERUID=0
TW_DOCKERGID=0
```

## Docker Compose

More experienced users may wish to use `docker-compose` to dynamically build a
customised container image using the Git source repostiory as the build context.
This allows control over the following `Dockerfile` build arguments:

* `TW_VERSION` - The upstream version of TiddlyWiki to install from NPM
  (https://www.npmjs.com/package/tiddlywiki)

* `BASE_IMAGE` - The Docker base container image to inherit from (should
  contain the `node` interpreter)

* `USER` - Unix user or UID to run the TiddlyWiki process as (useful if
  your container runtime environment does not allow you to override)

The `Makefile` in the https://gitlab.com/nicolaw/tiddlywiki.git also makes use
of these build arguments in a similar way.

Example partial [Docker compose](https://docs.docker.com/compose/) definition:

```yaml
tiddlywiki:
  container_name: tiddlywiki
  image: elquimista/tiddlywiki
  build:
    context: https://github.com/elquimista/tiddlywiki-docker.git
    args:
      TW_VERSION: 5.3.1
      USER: 501
      BASE_IMAGE: 20.9-alpine3.17
````

To use the provided https://github.com/elquimista/tiddlywiki-docker/blob/main/docker-compose.yaml:

```console
$ docker-compose up -d
Starting tiddlywiki ... done
```

## Packer AWS AMIs

A [Packer HCL definition](https://www.packer.io/) https://github.com/elquimista/tiddlywiki-docker/blob/main/docker-compose.yaml
provides an easy mechanism to build an AWS EC2 AMI.

```console
$ packer init .
$ packer build .
```

Public AWS AMIs are made available from the under the owner accound ID
`172306058616` in the `eu-west-2` EU London region.

```console
$ aws ec2 describe-images \
  --region eu-west-2 --owners 172306058616 \
  --filters 'Name=name,Values=tiddlywiki-*' 'Name=architecture,Values=x86_64' \
  --query 'sort_by(Images, &CreationDate)[-1].ImageId' --output text
ami-00e143acd635f8693
```

This TiddlyWiki AMI will listen on port 80 by default for greater convenience.

Tiddler data is stored in a bind mount under `/home/ec2-user/tiddlywiki` by
default.

Refer to the configuration variables documentation above to modify these
settings in the `/etc/tiddlywiki/tiddlywiki.conf` configuration file.
The TiddlyWiki service may be restarted using Systemd:

```console
$ systemctl restart tiddlywiki.service
```

## Credits

Nicola Worthington <nicolaw@tfb.net>, https://nicolaw.uk,
https://nicolaw.uk/#TiddlyWiki, https://gitlab.com/nicolaw/tiddlywiki.

## License

MIT License

Copyright (c) 2018-2022 Nicola Worthington

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
