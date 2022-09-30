ARG CERTBOTBUILD

FROM certbot/$CERTBOTBUILD

RUN apk update && apk add --no-cache docker-cli bash
ADD entrypoint.sh .

ENTRYPOINT [ "./entrypoint.sh" ]
