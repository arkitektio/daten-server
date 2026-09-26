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
      io.arkitekt.postgres.major="19" \
      io.arkitekt.pgvector="0.8.6" \
      io.arkitekt.postgis="3.6.4"

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

# pgvector: the `vector` type and its distance operators, behind the services' semantic
# `search` filters (rekuest actions, mikro folders/datasets store one embedding per row).
# PGDG packages it for the 19 beta on this base (the image ships `trixie-pgdg main 19` in
# its apt sources), so it is installed from apt and the image keeps no toolchain. Should
# the package ever lag the base, the fallback is pgvector's own recipe: ADD
# https://github.com/pgvector/pgvector.git#v0.8.6, build-essential +
# postgresql-server-dev-$PG_MAJOR, `make && make install`, then remove the toolchain.
# The extension is created per database by the init script below and by each service's
# migration (it is not `trusted`, so it needs the superuser either way).
#
# PostGIS: the `geography` type and its spatial functions, behind bank's merchant locations
# (`near` filters: ST_DWithin / ST_Distance over a GiST-indexed geography column). Also from
# PGDG for the 19 beta (3.6.4 on trixie). The services use it without GeoDjango (no GDAL in
# their images), so only the server side is needed here. Created like `vector`: by the init
# script on a new cluster, by the using service's migration on an existing one.
#
# Both are PINNED to builds made against this base's server (19beta3). A prerelease major
# changes its C ABI between betas, and PGDG rebuilds extensions for the newest beta under the
# same upstream version: pgvector 0.8.6-1.pgdg13+2 is built for 19beta4 and on this server
# fails `CREATE EXTENSION vector` ("index access method handler function … did not return an
# IndexAmRoutine struct"). Move these pins together with the base tag/digest.
ARG PGVECTOR_DEB=0.8.6-1.pgdg13+1
ARG POSTGIS_DEB=3.6.4+dfsg-2.pgdg13+1
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      postgresql-$PG_MAJOR-pgvector=$PGVECTOR_DEB \
      postgresql-$PG_MAJOR-postgis-3=$POSTGIS_DEB \
      postgresql-$PG_MAJOR-postgis-3-scripts=$POSTGIS_DEB \
 && rm -rf /var/lib/apt/lists/*

COPY ./create-multiple-databases.sh /docker-entrypoint-initdb.d/create-multiple-databases.sh
RUN chmod +x /docker-entrypoint-initdb.d/create-multiple-databases.sh
