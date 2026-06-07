# Operability Review Checklist

> Sources: Google SRE Book & SRE Workbook, The Twelve-Factor App, OpenTelemetry semantic conventions, Charity Majors (observability), progressive-delivery practice (feature flags / canary)
> Severity: Blocking / Suggestion / Observation
> Updated: 2026-06-02
>
> **Meta-principle:** Code is read in dashboards and incident channels as much as in the editor. A change is operable if, when it misbehaves in production, an on-call engineer can see what happened, contain it without a deploy, and roll back safely. Judge against how this service is already operated, not an abstract ideal.

## 1. Logging

| # | Item | Source | Severity |
|---|------|--------|----------|
| 1.1 | Failure path swallows the error with no log/metric — silent failure | SRE: observability | Blocking |
| 1.2 | Log lines lack correlation/trace/request id, making them un-joinable across a request | OTel conventions | Suggestion |
| 1.3 | Secrets, tokens, PII, or full request bodies logged | 12-Factor logs; privacy | Blocking |
| 1.4 | Logging in a hot loop / per-row at info level — log spam that drowns signal and costs money | SRE practice | Suggestion |
| 1.5 | Unstructured string logging where the codebase uses structured logging | Consistency | Suggestion |
| 1.6 | Log level misused: routine events at `error`, or genuine failures at `debug`/`info` | SRE practice | Suggestion |

## 2. Metrics & Tracing

| # | Item | Source | Severity |
|---|------|--------|----------|
| 2.1 | New critical path (external call, queue consumer, background job) added with no metric on rate/errors/duration (RED) | SRE: RED method | Suggestion, Blocking for core paths |
| 2.2 | Unbounded-cardinality label/tag (user id, request id, full URL) on a metric | OTel cardinality guidance | Blocking |
| 2.3 | New outbound dependency call not wrapped in a span / not traced where tracing exists | OTel conventions | Suggestion |
| 2.4 | SLI-relevant behaviour changed without updating the corresponding alert/SLO | SRE Workbook | Suggestion |

## 3. Failure Handling & Resilience

| # | Item | Source | Severity |
|---|------|--------|----------|
| 3.1 | External call with no timeout — can hang the caller indefinitely | SRE: cascading failure | Blocking |
| 3.2 | Retry without backoff/jitter or without a cap — retry storm / thundering herd risk | SRE: handling overload | Blocking |
| 3.3 | Retry on a non-idempotent operation without an idempotency key — duplicate side effects | Idempotency | Blocking |
| 3.4 | No circuit breaker / fallback for a dependency whose outage would cascade | SRE: cascading failure | Suggestion |
| 3.5 | Unbounded queue/buffer/concurrency with no backpressure or limit | SRE: handling overload | Suggestion, Blocking if memory-unbounded |
| 3.6 | Error path not graceful: partial failure leaves inconsistent state with no compensation | Reliability | Suggestion |

## 4. Configuration & Secrets

| # | Item | Source | Severity |
|---|------|--------|----------|
| 4.1 | Config hard-coded that should be environment-driven (hosts, timeouts, limits) | 12-Factor: config | Suggestion |
| 4.2 | Secret read from source/committed file instead of secret manager / env | 12-Factor; security | Blocking |
| 4.3 | New required config/env var added with no default and no startup validation — silent runtime failure later | 12-Factor; fail-fast | Suggestion |
| 4.4 | Behaviour differs by environment via code branches rather than config | 12-Factor: parity | Suggestion |

## 5. Deployability & Release Safety

| # | Item | Source | Severity |
|---|------|--------|----------|
| 5.1 | Risky behaviour change shipped without a feature flag / kill switch, forcing a deploy or rollback to disable | Progressive delivery | Suggestion, Blocking for high-blast-radius changes |
| 5.2 | Change requires a specific deploy/migration ordering that isn't documented or enforced | Expand-Contract | Blocking if order matters |
| 5.3 | Not backwards-compatible during rolling deploy: old and new instances run together and one breaks | 12-Factor: disposability | Blocking |
| 5.4 | No graceful shutdown / in-flight request draining for a long-running change | 12-Factor: disposability | Suggestion |
| 5.5 | Startup does heavy/blocking work that breaks healthcheck timing or fast scale-up | SRE practice | Suggestion |

## 6. Resource & Cost

| # | Item | Source | Severity |
|---|------|--------|----------|
| 6.1 | Unbounded memory growth (accumulating collection, cache without eviction) | Reliability | Blocking |
| 6.2 | New always-on background work (poller, cron, warm connection pool) with no off switch or sizing rationale | SRE practice | Suggestion |
| 6.3 | Per-item external/API call in a loop where a batch call exists — N+1 against a dependency | SRE: efficiency | Suggestion |
| 6.4 | Resource limits/requests (CPU/mem) or pool sizes changed without justification | Capacity practice | Observation |

## 7. Healthchecks & Lifecycle

| # | Item | Source | Severity |
|---|------|--------|----------|
| 7.1 | Healthcheck/readiness probe reports healthy while a critical dependency is down (false-positive readiness) | SRE practice | Suggestion |
| 7.2 | New critical dependency not represented in readiness, so traffic routes to an instance that can't serve | SRE practice | Suggestion |
| 7.3 | Liveness probe coupled to a flaky downstream, causing restart loops | SRE practice | Suggestion |

## Severity Escalation Guide

An operability finding is **Blocking** if it meets at least one: (a) creates a silent failure (no signal in logs/metrics on the failure path), (b) can cascade or amplify an outage (no timeout, unbounded retry/queue/memory), (c) leaks secrets/PII to logs, (d) breaks rolling deploys or requires undocumented ordering. Otherwise prefer Suggestion. Use Observation for tuning notes with no clear failure mode.
