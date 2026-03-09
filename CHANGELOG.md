# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.5.3] - 2026-03-09

### Fixed

- Require TeamCreate and fix task ownership across agent team workflow — teammates were spawned as subprocess agents instead of persistent team members, causing pipeline failures

## [1.5.2] - 2026-03-09

### Fixed

- Unset inherited upstream tracking when creating worktree branches

## [1.5.1] - 2026-03-09

### Changed

- Move WORKTREE phase to beginning of team-leader pipeline

## [1.5.0] - 2026-03-09

### Added

- Task metadata for agent I/O and refiner/shaper agents

## [1.4.0] - 2026-03-08

### Added

- Retrospective phase in team-leader workflow

### Changed

- Remove unnecessary spike report read from team-leader

### Fixed

- Deduplicate routing logic in team-leader ASSESS phase

## [1.3.0] - 2026-03-07

### Added

- Task-chain pipeline and event-driven team communication

## [1.2.0] - 2026-03-07

### Added

- Council planning model with diverge, vote, and critique workflow
- Acceptance criteria generation in planning workflow
- Peer-to-peer execution pipeline with spike phase and agent audit fixes

## [1.1.1] - 2026-03-06

### Fixed

- Prevent team-leader from bypassing delegation model by reading source files, invoking implementation skills, or skipping the ASSESS gate

## [1.1.0] - 2026-03-06

### Changed

- Audit and revalidate all skills for consistency and correctness
- Audit and revalidate all agents for consistency and correctness
- Improve author-agent skill with learnings from skill-creator usage
- Improve author-skill skill with learnings from skill-creator usage

## [1.0.0] - 2026-02-25

Initial release

[Unreleased]: https://github.com/jamesacarr/claude/compare/v1.5.3...HEAD
[1.5.3]: https://github.com/jamesacarr/claude/compare/v1.5.2...v1.5.3
[1.5.2]: https://github.com/jamesacarr/claude/compare/v1.5.1...v1.5.2
[1.5.1]: https://github.com/jamesacarr/claude/compare/v1.5.0...v1.5.1
[1.5.0]: https://github.com/jamesacarr/claude/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/jamesacarr/claude/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/jamesacarr/claude/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/jamesacarr/claude/compare/v1.1.1...v1.2.0
[1.1.1]: https://github.com/jamesacarr/claude/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/jamesacarr/claude/compare/v1.0.0...v1.1.0
