# ADR 0003: Audio Engine Isolation and Playback Lifecycle

## Status
Accepted

## Context
Audio engines and background media plugins evolve frequently. Coupling the domain or UI to a concrete player package creates massive refactoring risk when migrating or supporting background playback / Android Auto.

## Decision
Isolate all low-level audio playback behind the `AudioEngine` contract and separate playback queue management (`PlaybackQueue`) from engine controls in `PlaybackRepositoryImpl`.

## Consequences
- **Pros**:
  - The rest of the app never imports or calls native audio plugins directly.
  - Playback lifecycle is independent of the UI lifecycle.
  - Headless unit testing of queue logic, shuffle, and repeat without requiring native audio drivers.
- **Cons**:
  - Requires bridging low-level engine events to higher-level domain state.
