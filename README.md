# daten-server

The Postgres image of an [Arkitekt](https://arkitekt.live) deployment, published as
`jhnnsrs/daten`. It is the official `postgres` image, pinned by digest, plus three things:

- one database (and a user of the same name) per service, created on first start;
- the `cube`, `vector` and `postgis` extensions in each of them;
- a data directory that stays at `/var/lib/postgresql/data`, whatever the Postgres major.

It currently carries **PostgreSQL 19rc1**. That is a prerelease, on purpose: the stack
uses PostgreSQL 19's native SQL/PGQ (`CREATE PROPERTY GRAPH` / `GRAPH_TABLE`), which first
ships in 19. The tag and digest move to the release image together once 19 is final.
Apache AGE is not included.

## Usage

```yaml
db:
  image: jhnnsrs/daten
  environment:
    POSTGRES_USER: postgres
    POSTGRES_PASSWORD: changeme
    POSTGRES_MULTIPLE_DATABASES: lok_db,rekuest_db,mikro_db
  volumes:
    - ./data:/var/lib/postgresql/data
```

| Variable | What it is |
| --- | --- |
| `POSTGRES_USER`, `POSTGRES_PASSWORD` | The superuser, as in the official image. |
| `POSTGRES_MULTIPLE_DATABASES` | Comma-separated database names. Required: the init script aborts when it is unset. Set it to an empty string to create none. |

Each name gets a database, a user of the same name with all privileges on it, and the
three extensions. The user is created **without a password**; the Arkitekt services connect as
the superuser.

All of this happens in an init script, which only runs on the first start of an empty data
directory. Adding a name later creates nothing.

## Extensions

| Extension | Origin | Used by |
| --- | --- | --- |
| `cube` | PostgreSQL contrib (in the official image) | mikro's spatial annotation queries |
| `vector` | [pgvector](https://github.com/pgvector/pgvector) 0.8.6, from the PGDG apt repository | the services' semantic `search` filters (one embedding per row) |
| `postgis` | [PostGIS](https://postgis.net) 3.6.4, from the PGDG apt repository | bank's merchant locations (`geography` points, `ST_DWithin` / `ST_Distance`) |

A cluster created by an earlier image does not have `vector` or `postgis` in its
databases. There, each service's own migration creates them (`CREATE EXTENSION IF NOT
EXISTS …`), which works because the services connect as the superuser. With a locked-down
service user, run it once by hand as the superuser in each database.

Both packages are pinned to builds made against this exact server. A prerelease major
changes its C ABI between betas, so the pins move together with the base image; the
`Dockerfile` explains how.

## The data directory

Mount your volume at `/var/lib/postgresql/data`.

The official image moved its default in Postgres 18, to
`/var/lib/postgresql/<major>/docker`. This image sets `PGDATA` back, so a deployment written
against any version of it keeps working. A mount that lands beside the cluster instead of
on it gives a database that appears to work and is backed by nothing.

## Versions

Releases are tags: a push to `main` cuts a stable version, a push to `next` a release
candidate. Each one publishes `jhnnsrs/daten` for `linux/amd64` and `linux/arm64` under its
version (`X.Y.Z`, `X.Y`, `X`), plus `latest` from `main` and `next` from `next`. Release
notes are on [GitHub Releases](https://github.com/arkitektio/daten-server/releases).

The image version is its own and is not the Postgres major: every `1.x` carries PostgreSQL
19. The image label `io.arkitekt.postgres.major` names the major an image carries.

A cluster written by one Postgres major cannot be opened by another. Moving between them is
a migration, not an upgrade in place: dump on the old image, restore on the new one.

The same can hold between two prereleases of one major. A beta or release candidate may
change the catalog version, and the server then refuses to start on a cluster an earlier
prerelease wrote (`database files are incompatible with server`). It refuses rather than
damages anything: dump on the old image and restore on the new one, as between majors.
