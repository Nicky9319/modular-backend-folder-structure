# Generic AI Backend Template

This directory is a temporary, standalone export of the backend foundation.
It can be copied into a separate repository and removed from the main project
after the template repository is created.

The optional `prototype/` folder is reserved for experiments, testing ideas,
trying new technologies, and understanding unfamiliar tools. Prototype code
should not be treated as production backend code.

This backend uses a modular structure with documented boundaries between
controllers, services, repositories, queries, models, and migrations. That
makes it suitable for scaling across multiple developers and agents: each
person or agent can work within a focused layer while following the documented
process and conventions.

## Run locally

```bash
docker compose up --build
```

The startup order is PostgreSQL, database migrations, and then the FastAPI
backend. The API is available at <http://localhost:8000>.

Configuration is colocated with each runtime component:

```text
app/.env       # FastAPI settings
database/.env  # Alembic settings
```
