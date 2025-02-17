FROM alpine:latest
LABEL Author=Snorkrat
RUN apk update && apk add --no-cache docker-cli bash shadow gcc python3-dev py3-pip musl-dev libffi-dev openssl-dev
RUN pip install certbot \
    pip install certbot-dns-cloudflare \
    pip install certbot-dns-cloudxns \
    pip install certbot-dns-digitalocean \
    pip install certbot-dns-dnsimple \
    pip install certbot-dns-dnsmadeeasy \
    pip install certbot-dns-gehirn \
    pip install certbot-dns-google \
    pip install certbot-dns-godaddy \
    pip install certbot-dns-linode \
    pip install certbot-dns-luadns \
    pip install certbot-dns-nsone \
    pip install certbot-dns-ovh \
    pip install certbot-dns-rfc2136 \
    pip install certbot-dns-route53 \
    pip install certbot-dns-sakuracloud

ADD entrypoint.sh .

ENTRYPOINT [ "./entrypoint.sh" ]
