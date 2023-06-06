#!/bin/bash

trap "exit" SIGHUP SIGINT SIGTERM

echo " _____ _   _ ___________ _   ________  ___ _____ ";
echo "/  ___| \ | |  _  | ___ \ | / /| ___ \/ _ \_   _|";
echo "\ \`--.|  \| | | | | |_/ / |/ / | |_/ / /_\ \| |  ";
echo " \`--. \ . \` | | | |    /|    \ |    /|  _  || |  ";
echo "/\__/ / |\  \ \_/ / |\ \| |\  \| |\ \| | | || |  ";
echo "\____/\_| \_/\___/\_| \_\_| \_/\_| \_\_| |_/\_/  ";
echo "                                                 ";

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
  echo "
 +-+-+-+-+-+ +-+-+-+ +-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+-+-+-+
 |U|S|I|N|G| |T|H|E| |S|T|A|G|I|N|G| |E|N|V|I|R|O|N|M|E|N|T|
 +-+-+-+-+-+ +-+-+-+ +-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+-+-+-+
"
  ADDITIONAL="--staging"
fi

DOMAINS=(${DOMAINS})
CERTBOT_DOMAINS=("${DOMAINS[*]/#/--domain }")
CHECK_FREQ="${CHECK_FREQ:-30}"
DNS_PLUGIN="${DNS_PLUGIN}"
DNS_INI_PATH="${DNS_INI_PATH:-"/var/dns"}"
DNS_WAIT="${DNS_WAIT:-"10"}"

check() {
  echo "* Starting initial certificate request script for ${DNS_PLUGIN}..."

  certbot certonly --agree-tos --noninteractive --text ${ADDITIONAL} --expand \
      --email ${EMAIL} \
      --authenticator dns-${DNS_PLUGIN} \
      --dns-${DNS_PLUGIN}-credentials ${DNS_INI_PATH}/credentials.ini \
      --dns-${DNS_PLUGIN}-propagation-seconds ${DNS_WAIT} \
      ${CERTBOT_DOMAINS}

  echo "* Certificate request process finished for domain $DOMAINS"

  if [ "$CERTS_PATH" ] ; then
    echo "* Copying certificates to $CERTS_PATH"
    eval cp /etc/letsencrypt/live/$DOMAINS/* $CERTS_PATH/
  fi

  if [ "$SERVER_CONTAINER" ]; then
    echo "* Restarting $SERVER_CONTAINER"
    eval docker restart $SERVER_CONTAINER
  fi

  if [ "$SERVER_CONTAINER_LABEL" ]; then
    echo "* Restarting container with label $SERVER_CONTAINER_LABEL"

    container_id=`docker ps --filter label=$SERVER_CONTAINER_LABEL -q`
    eval docker restart $container_id
  fi

  echo "* Next check in $CHECK_FREQ days"

  if [[ $STAGING -eq 1 ]]; then
  echo " ";
  echo " +-+-+-+-+-+-+-+ +-+-+-+-+ +-+-+-+ +-+-+-+-+-+-+-+-+-+-+-+-+";
  echo " | | | |T|H|I|S| |C|E|R|T| |W|A|S| |G|E|N|E|R|A|T|E|D| | | |";
  echo " +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+";
  echo " |U|S|I|N|G| |T|H|E| |S|T|A|G|I|N|G| |E|N|V|I|R|O|N|M|E|N|T|";
  echo " +-+-+-+-+-+ +-+-+-+ +-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+-+-+-+";
  echo "        For a real cert please change -e 'STAGING=0'";
  echo " ";
  fi

  sleep ${CHECK_FREQ}d
  check
}

check
