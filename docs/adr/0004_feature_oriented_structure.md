# ADR 0004: Feature-Oriented Modular Structure

## Status
Accepted

## Context
As an application grows from a local offline music player into a full-scale music platform, monolithic layered structures (e.g. one global `presentation/` or `controllers/` directory) lead to tight coupling, unclear ownership, and circular dependencies.

## Decision
Organize the codebase into feature-first modules (`features/library`, `features/playback`, `features/playlists`, etc.) while maintaining shared domain contracts and infrastructure boundaries.

## Consequences
- **Pros**:
  - High cohesion within features, low coupling across features.
  - Adding new capabilities (e.g., lyrics, downloads, recommendations) requires creating isolated feature modules without modifying existing core logic.
  - Clear ownership and fast onboarding for developers.
- **Cons**:
  - Requires discipline to prevent feature modules from importing each other directly instead of using domain abstractions.
