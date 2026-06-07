# Data & Migration Safety Review Checklist

> Sources: Expand-Contract / Parallel Change (Fowler), Stripe & GitHub online-migration practices, PostgreSQL/MySQL locking semantics, "Database Reliability Engineering" (Campbell & Majors)
> Severity: Blocking / Suggestion / Observation
> Updated: 2026-06-02
>
> **Meta-principle:** Migrations run once against production data that cannot be re-created. A reversible application bug is a nuisance; an irreversible or locking migration is an incident. Bias severity upward for anything that runs DDL against a populated table or transforms existing rows.

## 1. Backwards Compatibility

| # | Item | Source | Severity |
|---|------|--------|----------|
| 1.1 | Schema change deployed without Expand-Contract: column renamed/dropped in the same release that stops writing it, so old and new app versions cannot both run during rollout | Fowler: Parallel Change | Blocking |
| 1.2 | Column or table dropped while code still references it (or vice versa): destructive DDL not separated from the deploy that removes the last reader/writer | Expand-Contract | Blocking |
| 1.3 | `NOT NULL` column added without a default or backfill: existing rows violate the constraint or the write fails | PostgreSQL/MySQL DDL | Blocking |
| 1.4 | Enum/check-constraint value removed while existing rows still hold it | Constraint semantics | Blocking |
| 1.5 | Type narrowed (e.g. `bigint`→`int`, `text`→`varchar(n)`) without verifying existing values fit | DDL semantics | Blocking |
| 1.6 | API/event-schema field made required or removed without a deprecation window for consumers | Parallel Change | Blocking for shared contracts |

## 2. Locking & Online Safety

| # | Item | Source | Severity |
|---|------|--------|----------|
| 2.1 | DDL takes a long-held exclusive lock on a large/hot table (e.g. `ALTER TABLE ... ADD COLUMN` with volatile default on older engines, table rewrite) | PostgreSQL lock levels | Blocking |
| 2.2 | Index created without `CONCURRENTLY` (PG) / online algorithm (MySQL) on a large table, blocking writes | PG `CREATE INDEX CONCURRENTLY` | Blocking on large tables |
| 2.3 | Constraint added as `VALIDATE` in one step instead of `ADD ... NOT VALID` then `VALIDATE CONSTRAINT` | PG online constraint pattern | Suggestion |
| 2.4 | Migration wrapped in a single transaction that holds locks across a long backfill | Locking semantics | Blocking |
| 2.5 | No statement/lock timeout set for a migration that could block production traffic indefinitely | DBRE practice | Suggestion |
| 2.6 | Foreign key added without `NOT VALID` first, forcing a full-table validation scan under lock | PG FK pattern | Suggestion |

## 3. Data Backfill & Transformation

| # | Item | Source | Severity |
|---|------|--------|----------|
| 3.1 | Backfill runs as a single `UPDATE` over a large table instead of batched/throttled chunks | DBRE practice | Blocking on large tables |
| 3.2 | Backfill is not idempotent: re-running after a partial failure double-applies or corrupts data | Idempotency principle | Blocking |
| 3.3 | Data transformation is lossy with no preserved source (drops precision, truncates, collapses values) without explicit sign-off | Data integrity | Blocking |
| 3.4 | Backfill reads/writes through application code paths that may change, rather than a pinned snapshot of logic | Reproducibility | Suggestion |
| 3.5 | No progress tracking / resumability for a long backfill (no cursor, no checkpoint) | Operability | Suggestion |
| 3.6 | Timezone/encoding/null-handling assumptions in the transform not validated against real data | Data integrity | Suggestion |

## 4. Rollback & Recovery

| # | Item | Source | Severity |
|---|------|--------|----------|
| 4.1 | Migration has no rollback path and the forward change is destructive (data dropped, not recoverable) | Migration discipline | Blocking |
| 4.2 | Down-migration exists but would itself lose data written after the up-migration | Reversibility | Suggestion |
| 4.3 | Deploy ordering not specified for a change that requires migrate-then-deploy or deploy-then-migrate | Expand-Contract | Blocking if order matters |
| 4.4 | No tested restore/verification path for a one-way destructive operation (e.g. snapshot taken first) | DBRE practice | Suggestion |

## 5. Integrity & Constraints

| # | Item | Source | Severity |
|---|------|--------|----------|
| 5.1 | Uniqueness/foreign-key invariant enforced only in application code, not in the schema, for data that must not duplicate | Data integrity | Suggestion, Blocking for money/identity data |
| 5.2 | New unique constraint added without first de-duplicating existing rows (migration will fail mid-flight) | Constraint semantics | Blocking |
| 5.3 | Default value set at the application layer only, leaving NULLs in the column for rows written by other paths | Consistency | Suggestion |
| 5.4 | Cascade behaviour (`ON DELETE CASCADE`) introduced without analysing blast radius on related tables | Referential integrity | Blocking |

## 6. Migration Hygiene

| # | Item | Source | Severity |
|---|------|--------|----------|
| 6.1 | Migration not idempotent / not guarded (`IF NOT EXISTS`) where the framework doesn't guarantee single application | Migration discipline | Suggestion |
| 6.2 | Schema change made directly without a tracked, versioned migration file | Reproducibility | Blocking |
| 6.3 | Migration mixes schema DDL and large data DML in one step, coupling fast and slow operations | Separation | Suggestion |
| 6.4 | Seed/reference data embedded in a schema migration rather than a separate data migration | Separation | Observation |

## Severity Escalation Guide

A data/migration finding is **Blocking** if it meets at least one: (a) can lock or take down a production table, (b) can lose or corrupt data irreversibly, (c) breaks compatibility between concurrently-running app versions during rollout, (d) will fail mid-migration against real data. Otherwise prefer Suggestion. Reserve Observation for hygiene notes with no production-risk path.
