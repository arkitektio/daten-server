# Daten-Server

This is a simple extensions to the PostgresSQL 15 Database Container, to provide support
for multiple databases and users, when running in a Docker environment.

## Usage

### Environment Variables

The following environment variables is supported:

```bash
POSTGRES_MULTIPLE_DATABASE=database1,database2
```