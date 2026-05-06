FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        default-mysql-client postgresql-client \
    && rm -rf /var/lib/apt/lists/*

COPY db-init/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER nobody

ENTRYPOINT ["/entrypoint.sh"]
