# ADR 0002: Local-First Storage Strategy with SQLite and Versioned Migrations

## Status
Accepted

## Context
The music player must operate with zero network latency and support tens of thousands of tracks locally, with fast indexed queries, sorting, pagination, and deterministic schema evolution.

## Decision
Use SQLite (`sqflite` / `sqflite_common_ffi`) behind a `DatabaseMigrator` versioned migration engine and dedicated local data sources.

## Consequences
- **Pros**:
  - Direct SQL indexing on `title`, `artist`, `album`, and `date_added` for sub-millisecond lookups.
  - Safe migrations from Day 1, ensuring schema evolution without data loss.
  - Paginated queries preventing out-of-memory errors on huge collections.
  - Cross-platform support for Android, Windows, and unit tests via FFI.
- **Cons**:
  - Requires explicit row mappers and SQL schema management.
