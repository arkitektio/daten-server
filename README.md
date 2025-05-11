# Daten-Server

This is a simple extensions to the PostgresSQL 16 Database Container, to provide support
for multiple databases and users, when running in a Docker environment, it also comes included with the Apache AGE extension.

## Usage

### Environment Variables

The following environment variables are supported:

```bash
POSTGRES_MULTIPLE_DATABASE=database1,database2
POSTGRES_PASSWORD: $THE_GLOBAL_PASSWORD
POSTGRES_USER:  $THE_GLOBAL_USER
```

### Volumes

To persist the data, you can mount a volume to the following path:

```yaml

volumes:
    - /path/to/mount:/var/lib/postgresql/data
```
## Roadmap

- [x] Add arm 64 support
- [ ] Switch to stable release