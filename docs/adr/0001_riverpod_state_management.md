# ADR 0001: Riverpod for State Management and Dependency Injection

## Status
Accepted

## Context
A high-performance music player requires modular, granular state management with fine-grained reactivity, lifecycle safety, and easy dependency overriding for testing and platform swapping.

## Decision
Adopt `flutter_riverpod` (v2.x) as the unified state management and dependency injection foundation.

## Consequences
- **Pros**:
  - Compile-time safety and zero global mutable singletons.
  - Automatic disposal and lifecycle cleanup for streams, listeners, and controllers.
  - Granular reactivity preventing unnecessary UI rebuilds across large track lists.
  - Seamless override capabilities in unit and integration tests.
- **Cons**:
  - Requires developers to adhere to provider scoping conventions.
