# Stock official Postgres. This image used to be Apache AGE's release image, because
# kraph's projection was an AGE graph; kraph draws into ordinary tables now (kraph RFC
# 0005) and no service in the stack loads the extension, so the base is the official image
# again. Pinned by digest as well as by tag, because a version tag is only as immutable as
# the base it was built from — and 19beta3 is a prerelease tag on top of that: move tag and
# digest together to the release image when 19 goes GA (expected Sept/Oct 2026).
FROM postgres:19beta3@sha256:a48b19841e04b35b72a25e9a94314ac80546d32b5e2e3cd9279390cbd8a99572

# Set by CI from the git tag. The major is the Postgres major on purpose: for this image
# that is the only breaking change there is, since a cluster written by one major cannot be
# opened by another. (18 → 19 is exactly that: dump on the old image, restore on this one.)
ARG VERSION="0.0.0"

LABEL org.opencontainers.image.title="daten" \
      org.opencontainers.image.description="PostgreSQL with multiple-database support" \
      org.opencontainers.image.source="https://github.com/arkitektio/daten-server" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.version="${VERSION}" \
      io.arkitekt.postgres.major="19"

# Postgres 18's official image moved the cluster: `PGDATA` became
# /var/lib/postgresql/<major>/docker (on 19: /var/lib/postgresql/19/docker) and its
# `VOLUME` became /var/lib/postgresql, where every earlier image used
# /var/lib/postgresql/data for both. Every deployment that mounts this image mounts the
# old path, so without this pin the mount would land beside the cluster rather than on
# it — the database would come up, write into the image's own anonymous volume, and
# backups would copy an empty directory while `down -v` threw the real data away.
#
# Holding PGDATA where it has always been is the whole point of a wrapper image: the major
# underneath may move, the contract with the deployment may not.
ENV PGDATA=/var/lib/postgresql/data

COPY ./create-multiple-databases.sh /docker-entrypoint-initdb.d/create-multiple-databases.sh
RUN chmod +x /docker-entrypoint-initdb.d/create-multiple-databases.sh
