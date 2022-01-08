FROM nginx:latest

ARG TZ

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update \
    && apt-get install -y cron bash wget certbot

COPY letsencrypt/. /etc/letsencrypt
COPY ./bin /bin
RUN chmod +x /bin/*.sh

RUN echo '59 23 * * * sudo certbot renew --post-hook "systemctl reload nginx"' >/etc/cron.d/certbot-renew

ENTRYPOINT ["/bin/entrypoint.sh"]

# Run both nginx and cron together
CMD [ "sh", "-c", "cron && nginx -g 'daemon off;'" ]
