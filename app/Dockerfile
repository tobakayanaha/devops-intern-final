FROM nginx:1.27-alpine

ARG BUILD_SHA=unknown
ENV BUILD_SHA=${BUILD_SHA}

# Custom config: serves on 8080, adds /healthz, non-root-friendly temp paths.
COPY nginx.conf /etc/nginx/nginx.conf

# Static site.
COPY index.html /usr/share/nginx/html/index.html

# Inject build metadata into the page at build time.
RUN sed -i "s/__BUILD_SHA__/${BUILD_SHA}/g" /usr/share/nginx/html/index.html

# nginx:alpine images already ship an 'nginx' user (uid 101). We just need
# to make sure it can write where nginx needs to write at runtime.
RUN mkdir -p /tmp/client_temp /tmp/proxy_temp /tmp/fastcgi_temp \
             /tmp/uwsgi_temp /tmp/scgi_temp && \
    chown -R nginx:nginx /usr/share/nginx/html /var/cache/nginx /tmp \
                          /etc/nginx/nginx.conf && \
    touch /var/run/nginx.pid && \
    chown nginx:nginx /var/run/nginx.pid

USER nginx

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -q -O- http://127.0.0.1:8080/healthz || exit 1

CMD ["nginx", "-g", "daemon off;"]