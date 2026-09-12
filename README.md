# Daten-Server

A small extension of the official PostgreSQL container that adds support for creating
multiple databases and users at first start.

Built on the official `postgres` image, pinned by digest. It currently carries
**PostgreSQL 19beta3** — a prerelease, deliberately: the stack uses PostgreSQL 19's
native SQL/PGQ (`CREATE PROPERTY GRAPH` / `GRAPH_TABLE`), which first ships in 19.
When 19 goes GA (expected Sept/Oct 2026), the tag and digest move to the release
image together. Apache AGE is no longer included — kraph's graph projection lives in
ordinary tables now, with SQL/PGQ as the query surface on top.

## Usage

### Environment Variables

The following environment variables are supported:

```bash
POSTGRES_MULTIPLE_DATABASES=database1,database2
POSTGRES_PASSWORD: $THE_GLOBAL_PASSWORD
POSTGRES_USER:  $THE_GLOBAL_USER
```

Each database listed gets its own user of the same name, with the `cube` extension
loaded into it.

### Volumes

To persist the data, mount a volume at:

```yaml
volumes:
    - /path/to/mount:/var/lib/postgresql/data
```

This path is fixed by the image and does not move with the Postgres major. Postgres 18's
official image changed its own default to `/var/lib/postgresql/<major>/docker`; this image
sets `PGDATA` back, so that a deployment written against any version of it keeps working.
A mount that lands beside the cluster rather than on it is a database that appears to work
and is backed by nothing.

### Versioning

The image is versioned `MAJOR.MINOR.PATCH` where **the major is the PostgreSQL major**.
For this image that is the only breaking change there is: a cluster written by one major
cannot be opened by another, so moving between them is a migration — dump and restore, not
an upgrade in place. `18.x` (the last AGE-carrying line) is maintained on the `18.x`
branch.

## Roadmap

- [x] Add arm 64 support
- [x] Switch to stable release
- [ ] Move to the PostgreSQL 19 release image at GA (currently 19beta3)

### License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
