# Database backup and restore

The repeatable backup scripts are in this folder. Use `dump-database.sh` to
create an archive and `restore-database.sh` to populate another PostgreSQL
instance.

This project uses PostgreSQL 16 and stores its data in the Docker volume
`postgres_data`. A PostgreSQL dump is the portable backup: it can be copied to
another machine and restored into a new PostgreSQL instance without copying the
Docker volume itself.

## Before you start

Make sure the database is running:

```bash
docker compose up -d postgres
```

The commands below use the values from `docker-compose.yml`:

```text
Database: trainme
User:     trainme
Host:     localhost
Port:     5432
Password: trainme
```

For a non-development environment, replace these values with the actual
credentials. Do not commit a backup file or production credentials to the
repository.

## Create a transferable backup

Run the repository script from the repository root, or use its absolute path:

```bash
database/docs/backup/dump-database.sh
```

The script creates a compressed, transferable PostgreSQL custom-format archive
and a SHA-256 checksum under `database/docs/backup/exports/`.

The equivalent manual commands are:

```bash
mkdir -p backups

docker compose exec -T postgres \
  pg_dump -U trainme -d trainme \
  --format=custom --file=/tmp/trainme.dump

docker compose cp postgres:/tmp/trainme.dump \
  "backups/trainme-$(date +%Y%m%d-%H%M%S).dump"

docker compose exec -T postgres rm -f /tmp/trainme.dump
```

The resulting `.dump` file is the database backup. Transfer it using your
approved secure storage or file-transfer method. Keep a checksum alongside the
file when transferring it:

```bash
sha256sum backups/trainme-YYYYMMDD-HHMMSS.dump \
  > backups/trainme-YYYYMMDD-HHMMSS.dump.sha256
```

To include PostgreSQL roles and other cluster-level objects, export globals as
a separate file. `pg_dump` contains the database schema and data, but not
cluster-wide roles or tablespaces.

```bash
docker compose exec -T postgres \
  pg_dumpall -U trainme --globals-only \
  > backups/trainme-globals-$(date +%Y%m%d-%H%M%S).sql
```

For this local Compose setup, the application role is created by the container
environment, so the custom archive is normally sufficient. Preserve the
globals file when moving a backup to a different PostgreSQL cluster.

## Restore into another PostgreSQL instance

Install the PostgreSQL client tools so `pg_restore` is available, set the
target connection variables, and run:

```bash
export PGHOST=localhost
export PGPORT=5432
export PGDATABASE=trainme
export PGUSER=trainme
export PGPASSWORD=your-target-password

database/docs/backup/restore-database.sh \
  database/docs/backup/exports/trainme-YYYYMMDD-HHMMSS.dump
```

The target database must already exist. The script uses `--clean --if-exists`,
so matching objects in the target database are replaced. Do not run it against
a production database unless overwriting that database is intended.

Restore cluster-level objects separately when you created a globals file:

```bash
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d postgres \
  < backups/trainme-globals-YYYYMMDD-HHMMSS.sql
```

## Plain SQL alternative

Use a plain SQL file when maximum readability or compatibility with basic SQL
tools is more important than selective restore:

```bash
docker compose exec -T postgres \
  pg_dump -U trainme -d trainme --format=plain \
  > backups/trainme-YYYYMMDD-HHMMSS.sql
```

Restore it with:

```bash
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" \
  < backups/trainme-YYYYMMDD-HHMMSS.sql
```

## Verify a backup

Check the checksum before restoring:

```bash
sha256sum --check \
  database/docs/backup/exports/trainme-YYYYMMDD-HHMMSS.dump.sha256
```

Inspect the archive contents:

```bash
pg_restore --list database/docs/backup/exports/trainme-YYYYMMDD-HHMMSS.dump \
  | sed -n '1,40p'
```

After restoring, verify that the expected tables and row counts are present:

```bash
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" \
  -c '\\dt' \
  -c 'SELECT COUNT(*) FROM users;'
```

For a reliable disaster-recovery process, perform a test restore periodically
into a separate database or PostgreSQL instance. A backup is only useful if it
can be restored successfully.

## Backup and migration relationship

Backups preserve the current schema and data. Alembic migrations in
`database/versions` remain the source of truth for evolving the schema. After a
restore, run the normal migration entrypoint if the application version is
newer than the restored database:

```bash
docker compose run --rm database-migration
```
