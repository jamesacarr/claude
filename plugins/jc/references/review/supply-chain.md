# Supply-Chain Review Checklist

> Sources: OWASP Top 10 CI/CD Security Risks, SLSA framework, OpenSSF Scorecard, npm/PyPI advisory practice, CWE-1357 (reliance on insufficiently trustworthy component)
> Severity: Blocking / Suggestion / Observation
> Updated: 2026-06-02
>
> **Meta-principle:** A dependency change adds code you didn't write and now ship. The review question is not "does it work" but "what did we just grant the right to run, and can we reproduce and trust it." Scope findings to changed manifests, lockfiles, and CI/build config in the diff.

## 1. New & Changed Dependencies

| # | Item | Source | Severity |
|---|------|--------|----------|
| 1.1 | New direct dependency added for trivial functionality achievable with stdlib / existing deps | YAGNI; attack surface | Suggestion |
| 1.2 | New dependency is unmaintained, low-adoption, or single-maintainer for a security-sensitive role (crypto, auth, parsing) | OpenSSF Scorecard | Blocking for security-sensitive, else Suggestion |
| 1.3 | Dependency name is a plausible typosquat / namespace-confusable with a popular package | Typosquat advisories | Blocking |
| 1.4 | Major version bump pulled in without reviewing its changelog/breaking changes | Upgrade discipline | Suggestion |
| 1.5 | Dependency duplicated at multiple versions in the tree where one would do | Hygiene | Observation |

## 2. Version Pinning & Reproducibility

| # | Item | Source | Severity |
|---|------|--------|----------|
| 2.1 | Dependency specified with a floating/range version (`^`, `~`, `*`, `latest`) for an application (non-library) build | SLSA: reproducible builds | Suggestion, Blocking for `latest`/`*` |
| 2.2 | Manifest changed but lockfile not updated (or vice versa) — drift between intended and resolved versions | Lockfile integrity | Blocking |
| 2.3 | Lockfile integrity hashes removed/weakened, or `--no-frozen-lockfile`/`--no-verify` introduced in CI | OWASP CI/CD | Blocking |
| 2.4 | Git/URL/tarball dependency pointing at a mutable ref (branch, `HEAD`) instead of a pinned commit/tag | SLSA | Suggestion, Blocking for branch refs |
| 2.5 | Vendored/bundled dependency updated without provenance (where it came from, what version) | SLSA: provenance | Suggestion |

## 3. Known Vulnerabilities & Licence

| # | Item | Source | Severity |
|---|------|--------|----------|
| 3.1 | Added/updated dependency has a known advisory at the resolved version (audit not run / not clean) | npm/PyPI advisories | Blocking for high/critical |
| 3.2 | Update pins to an older version than currently resolved, silently reintroducing a patched vulnerability | Regression | Blocking |
| 3.3 | New dependency licence is incompatible with the project's licence/policy (e.g. copyleft into proprietary) | Licence compliance | Blocking |
| 3.4 | Transitive dependency pulled in with a materially larger or riskier sub-tree than the direct add implies | Attack surface | Suggestion |

## 4. Install & Build Execution

| # | Item | Source | Severity |
|---|------|--------|----------|
| 4.1 | Dependency runs install/postinstall lifecycle scripts and execution is not disabled/reviewed | OWASP CI/CD; npm scripts | Blocking for untrusted, else Suggestion |
| 4.2 | Build/CI step added that pipes a remote script to a shell (`curl ... \| sh`) | OWASP CI/CD | Blocking |
| 4.3 | New build tooling fetches dependencies from a non-default / unpinned registry or mirror | SLSA | Suggestion |
| 4.4 | CI workflow grants broad write/secrets scope to a step that runs third-party code | OWASP CI/CD risk; least privilege | Blocking |
| 4.5 | Third-party CI action/plugin referenced by mutable tag (`@v1`, `@main`) rather than a pinned commit SHA | OWASP CI/CD | Suggestion |

## 5. Registry & Provenance

| # | Item | Source | Severity |
|---|------|--------|----------|
| 5.1 | Internal/private package name could be shadowed by a public package of the same name (dependency confusion) | Dependency confusion advisories | Blocking |
| 5.2 | Registry/source switched without scoping, risking resolution from an untrusted source | SLSA | Suggestion |
| 5.3 | No provenance/signature verification where the ecosystem supports it (e.g. npm provenance, sigstore) | SLSA; sigstore | Observation |

## Severity Escalation Guide

A supply-chain finding is **Blocking** if it meets at least one: (a) enables arbitrary code execution at install/build/CI time, (b) introduces or reintroduces a known high/critical vulnerability, (c) breaks reproducibility (lockfile drift, removed integrity, floating `latest`), (d) creates dependency-confusion/typosquat exposure, (e) violates licence policy. Otherwise prefer Suggestion. Use Observation for hygiene with no exploit or reproducibility path.
