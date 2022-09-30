#!/bin/bash

trap "exit" SIGHUP SIGINT SIGTERM

 echo "
========================
 __    _  _     _  _ ___
(_ |\|/ \|_)|/ |_)|_| | 
__)| |\_/| \|\ | \| | | 

========================"

if [ -z "$DOMAINS" ] ; then
  echo "No domains set, please fill -e 'DOMAINS=example.com www.example.com'"
  exit 1
fi

if [ -z "$EMAIL" ] ; then
  echo "No email set, please fill -e 'EMAIL=your@email.tld'"
  exit 1
fi

if [ -z "$DNS_PLUGIN" ] ; then
  echo "No DNS plugin set, please fill -e 'DNS_PLUGIN=eg:digitalocean'"
  exit 1
fi

if [[ $STAGING -eq 1 ]]; then
  echo "USING THE STAGING ENVIRONMENT"
  ADDITIONAL="--staging"
fi

DOMAINS=(${DOMAINS})
CERTBOT_DOMAINS=("${DOMAINS[*]/#/--domain }")
CHECK_FREQ="${CHECK_FREQ:-30}"
DNS_PLUGIN="${DNS_PLUGIN}"
DNS_INI_PATH="${DNS_INI_PATH:-"/var/dns"}"

check() {
  echo "* Starting DNS Plugin initial certificate request script..."

  certbot certonly --agree-tos --noninteractive --text ${ADDITIONAL} --expand \
      --email ${EMAIL} \
      --dns-${DNS_PLUGIN} \
      --dns-${DNS_PLUGIN}-credentials ${DNS_INI_PATH}/credentials.ini \
      ${CERTBOT_DOMAINS}

  echo "* Certificate request process finished for domain $DOMAINS"

  if [ "$CERTS_PATH" ] ; then
    echo "* Copying certificates to $CERTS_PATH"
    eval cp /etc/letsencrypt/live/$DOMAINS/* $CERTS_PATH/
  fi

  if [ "$SERVER_CONTAINER" ]; then
    echo "* Restarting $SERVER_CONTAINER"
    eval docker kill -s HUP $SERVER_CONTAINER
  fi

  if [ "$SERVER_CONTAINER_LABEL" ]; then
    echo "* Restarting container with label $SERVER_CONTAINER_LABEL"

    container_id=`docker ps --filter label=$SERVER_CONTAINER_LABEL -q`
    eval docker kill -s HUP $container_id
  fi

  echo "* Next check in $CHECK_FREQ days"

  if [[ $STAGING -eq 1 ]]; then
  echo "** REMINDER: This cert was generated using the STAGING environment.  For a real cert please change -e 'STAGING=0'"
  fi

  sleep ${CHECK_FREQ}d
  check
}

check
