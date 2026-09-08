# Database backup tools

This folder contains the database backup guide and scripts. Generated dump
files are stored in `exports/` by default, so the scripts remain easy to copy
without mixing them with backup artifacts.

## Create a dump

Start PostgreSQL, then run this from any directory:

```bash
docker compose up -d postgres
database/docs/backup/dump-database.sh
```

The script creates a compressed, transferable PostgreSQL custom-format archive
and a SHA-256 checksum under `database/docs/backup/exports/`.

To choose another output directory:

```bash
database/docs/backup/dump-database.sh /path/to/backup-directory
```

## Restore a dump

Install the PostgreSQL client tools so `pg_restore` is available, then set the
target connection variables and run:

```bash
export PGHOST=localhost
export PGPORT=5432
export PGDATABASE=trainme
export PGUSER=trainme
export PGPASSWORD=your-target-password

database/docs/backup/restore-database.sh /path/to/trainme-YYYYMMDD-HHMMSS.dump
```

The target database must already exist. The script uses `--clean --if-exists`,
so matching objects in the target database are replaced. Do not run it against
a production database unless overwriting that database is intended.

For the local Compose database, the defaults match `docker-compose.yml`:

```bash
docker compose up -d postgres
database/docs/backup/restore-database.sh \
  database/docs/backup/exports/trainme-YYYYMMDD-HHMMSS.dump
```

For the full guide, including verification and the optional cluster globals
export, see [database-backup-and-restore.md](database-backup-and-restore.md).
