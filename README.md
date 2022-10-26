# snorkrat/auto-letsencrypt-dns

A Docker image to automatically request and renew SSL/TLS certificates from [Let's Encrypt](https://letsencrypt.org/) using [certbot](https://certbot.eff.org/about/) and the [DNS-Plugins](https://eff-certbot.readthedocs.io/en/stable/using.html#dns-plugins) method for domain validation. This image is also capable of sending a restart command to a Docker container running a web server in order to use the freshly minted certificates.

The reason I made (modified) this was because I needed to have a secondary way to validate domain ownership while using [LinuxServer SWAG](https://github.com/linuxserver/docker-swag).  I use Cloudflare for my domain dns management, however I recently acquired some free domains (.tk, .ml, etc) which are blocked from using Cloudflare's API.  DigitalOcean also provide free DNS management, so I wanted to use their API to update my DNS recods for my free domains.  I use this to generate the certs and place them in a directory which is mapped to my SWAG continer.  I then created a secondary ssl.conf (ssl2.conf) file which points to the location of those certs.  Then in my subdomain.conf I can specify my ssl2.conf file so that it uses the correct certs for the alternate domain.

I exclusively use Docker Compose, so all examples will assume that you are using Docker Compose as well.

Currently supports linux/amd64, linux/arm64/v8, linux/arm32/v6, and linux/arm32/v7.

## Example Usage

### Specify Certbot DNS-Plugin

As this image uses the DNS-Plugin method, you need to specify the which DNS-Plugin to use.  See [Certbot - DNS Plugins](https://eff-certbot.readthedocs.io/en/stable/using.html#dns-plugins) for a list of plugins.  Please set this in the `DNS_PLUGIN` environment variable your docker-compose.yml.

A Docker Compose snippit to show this config:
```
    environment:
      - DOMAINS=example.com *.example.com
      - SERVER_CONTAINER=swag
      - DNS_PLUGIN=digitalocean
```

### Create credentials.ini and map the host directory to the container
Please see the relevant [DNS-Plugins](https://eff-certbot.readthedocs.io/en/stable/using.html#dns-plugins) page for what you should include in your credentials.ini file.  Create this file on the host, and map the directory to the container.

A Docker Compose snippit to show this config:
```
    environment:
      - DNS_INI_PATH=/var/dns
    volumes:
      - /path/to/host/dns/credentials:/var/dns
```
### Server Config

Your server container should be configured to be able use certificates retrieved by `certbot`. The certificates can be found at `/etc/letsencrypt/live/example.com` or be copied to a directory of your choice (see below). For example, using Nginx:

```
ssl_certificate     /etc/letsencrypt/live/example.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
```


The container will attempt to request and renew SSL/TLS certificates for the specified domains and automatically repeat the renew process periodically (default is every 30 days).

### Persistant Storage

Certbot stores the generated certs in the `/etc/letsencrypt` directory.  You should map this (even if you specify `CERTS_PATH`) to a directory on the host so that certbot does not generate new certs on container creation, but rather by how long is left before the certificate expires.

## Optional features

### Wildcard Certificates
To generate a wildcard certificate for `*.example.com` which covers all subdomains, please also include the root domain in the `DOMAINS` environment variable. 

A Docker Compose snippit to show this config:
```
    environment:
      - DOMAINS=example.com *.example.com
```
### Reload server configuration
To automatically reload the server configuration to use the new certificates, provide the container name to the environment variable `SERVER_CONTAINER` and pass through the Docker socket to this container: `-v /var/run/docker.sock:/var/run/docker.sock`. The image will send a `docker restart` command to the specified container.

### Copy certificates to another directory
Provide a directory path to the `CERTS_PATH` environment variable if you wish to copy the certificates to another directory. You may wish to do this in order to avoid exposing the entire `/etc/letsencrypt/` directory to your web server container.

### Change the check frequency
Provide a number to the `CHECK_FREQ` environment variable to adjust how often it attempts to renew a certificate. The default is 30 days. Please note `certbot` is configured to keep matching certificates until one is due for renewal.

### Use the Staging environment
Add the `STAGING` environment variable with a value of `1` to enable the staging environment.  This is useful for testing as you will not hit letsencrypt rate limits.  When everything is working, change the `STAGING` environment to `0` to generate a real cert.

## An example using Docker Compose

```
version: "3.9"
services:
  auto-letsencrypt-dns:
    build:
      context: ./dir
      dockerfile: Dockerfile
    image: myimage/auto-letsencrypt-dns
    container_name: auto-letsencrypt-dns
    environment:
      - DOMAINS=example.com
      - EMAIL=email@example.com
      - DNS_PLUGIN=digitalocean
      - DNS_INI_PATH=/var/dns
      - CHECK_FREQ=30
      - CERTS_PATH=/etc/certs
      - STAGING=1
      - SERVER_CONTAINER=swag
      - DNS_WAIT=15
    entrypoint: ./entrypoint.sh
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /path/on/host/letsencrypt:/etc/letsencrypt
      - /path/on/host/cert/dir:/etc/certs
      - /path/on/host/dns/credentials:/var/dns
    restart: always
```

### Environment variables

* **DOMAINS**: Domains for your certificate. e.g. `example.com www.example.com`.
* **DNS_PLUGIN**: Specifiy the DNS-Plugin to use. e.g. `digitalocean`.
* **EMAIL**: Email for urgent notices and lost key recovery. e.g. `your@email.tld`.
* **DNS_INI_PATH** Optional. Path to the credentials.ini directory in the web server for checks. Defaults to `/var/dns`.
* **CERTS_PATH**: Optional. Copy the new certificates to the specified path. e.g. `/etc/nginx/certs`.
* **SERVER_CONTAINER**: Optional. The Docker container name of the server you wish to send a `docker restart` command to in order to reload its configuration and use the new certificates.
* **SERVER_CONTAINER_LABEL**: Optional. The Docker container label of the server you wish to send a `docker restart` command to in order to reload its configuration and use the new certificates. This environment variable will be helpfull in case of deploying with docker swarm since docker swarm will create container name itself.
* **CHECK_FREQ**: Optional.  How often (in days) to perform checks. Defaults to `30`.
* **DNS_WAIT**: Optional.  How long (in seconds) to wait for DNS propagation.  Defaults to `10`.


A modified version of [gchan/auto-letsencrypt](https://github.com/gchan/auto-letsencrypt)

#### License

Copyright (c) 2016 Gordon Chan. Released under the MIT License. It is free software, and may be redistributed under the terms specified in the [LICENSE](https://github.com/gchan/dockerfiles/blob/master/LICENSE.txt) file.
