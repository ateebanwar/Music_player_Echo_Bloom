# Echo Bloom Architecture Guide

## Overview
Echo Bloom is built on a **feature-oriented, local-first, performance-obsessed architecture**. The application is designed to function with zero network dependencies as a lightning-fast offline music player, while maintaining strict architectural boundaries that allow future additions (cloud sync, remote streaming, user accounts, remote metadata, lyrics) to be integrated without breaking existing systems.

---

## 1. Directory Structure

```
lib/
├── app/                  # Application bootstrap, routing, config, startup coordinator
│   ├── app.dart          # Headless root widget & ProviderScope
│   ├── bootstrap/        # Environment & dependency bootstrapping
│   ├── config/           # AppConfig, BuildConfig, FeatureFlags
│   ├── routing/          # AppRouter & route definitions
│   └── startup/          # StartupCoordinator & priority-based tasks
│
├── core/                 # Cross-cutting primitives (zero feature logic)
│   ├── constants/        # Centralized storage keys & config identifiers
│   ├── errors/           # Typed Failure hierarchy & infrastructure AppExceptions
│   ├── extensions/       # Core utility extensions
│   ├── logging/          # AppLogger contract & production ConsoleLogger
│   ├── result/           # Sealed Result<T, Failure> monad with pattern matching
│   ├── time/             # Injectable Clock interface for deterministic testing
│   └── types/            # PageQuery, PaginatedList<T>
│
├── domain/               # Pure business domain (zero UI, zero infrastructure)
│   ├── entities/         # Track, Artist, Album, Playlist, PlaybackState
│   ├── repositories/     # Repository contracts (Track, Playlist, History, etc.)
│   └── use_cases/        # Single-responsibility use cases
│
├── data/                 # Data access & persistence implementations
│   ├── local/            # SQLite AppDatabase, DatabaseMigrator, schema v1, data sources
│   ├── remote/           # Future remote music data source contracts
│   ├── mappers/          # DB Row <-> Domain Entity translators
│   └── repositories/     # Concrete repository implementations
│
├── features/             # Feature-first modular capabilities
│   ├── library/          # Local music library query & pagination
│   ├── playback/         # PlaybackQueue, PlaybackRepositoryImpl, state providers
│   ├── playlists/        # Playlist management
│   ├── favorites/        # Favorite tracks management
│   ├── search/           # Indexed local & remote search
│   ├── history/          # Playback history & statistics
│   ├── settings/         # Persisted user preferences
│   ├── lyrics/           # Lazy lyrics resolution contract & providers
│   └── downloads/        # Offline download manager contract & providers
│
├── infrastructure/       # Platform & system implementations
│   ├── audio/            # AudioEngine contract & AudioEngineImpl
│   ├── permissions/      # PermissionService contract & implementation
│   ├── platform/         # MediaScanner contract & background progress
│   ├── networking/       # NetworkClient contract
│   └── storage/          # KeyValueStore contract & SqliteKeyValueStore
│
└── main.dart             # Bootstrap initialization and app execution
```

---

## 2. Dependency Direction

```
Presentation / UI (Future Phase)
       ↓
Feature Controllers / StateNotifiers
       ↓
Domain (Entities, Use Cases, Repository Contracts)
       ↓
Data Layer (Data Sources, Mappers, Repositories)
       ↓
Infrastructure (AudioEngine, SQLite Database, Platform Services)
```

### Strict Rules:
1. **Domain Isolation**: Domain entities, use cases, and contracts have **zero dependencies** on Flutter UI, database drivers, audio packages, or HTTP clients.
2. **Audio Engine Isolation**: Playback state and controllers interact with `AudioEngine` strictly through its interface contract. The underlying audio player (e.g. `just_audio`, ExoPlayer, OpenSL) can be swapped without touching domain or state controllers.
3. **Local-First Precedence**: The local SQLite database is the primary source of truth for library metadata, playlists, and history. Remote APIs plug in as optional data sources behind the repository contracts.
4. **No Feature-to-Feature Circular Dependencies**: Feature modules communicate only through shared domain entities or typed event streams.

---

## 3. State Management (Riverpod)
- State is feature-scoped using `StateNotifier` and Riverpod `Provider`.
- Granular providers prevent unnecessary rebuilds.
- Heavy dependencies are lazily initialized on-demand.

---

## 4. Local Persistence & Migrations
- SQLite database (`sqflite` with FFI support for desktop & tests) with foreign keys and compound indexes on title, artist, album, and dateAdded.
- Versioned, deterministic migrations orchestrated by `DatabaseMigrator`.

---

## 5. Startup Performance Budget
- **Critical Phase**: Only foundational config and database readiness execute before app mount.
- **Background Phase**: Media scanners, indexing, and cache warmups execute asynchronously without blocking startup.
- **Lazy Phase**: Lyrics, downloads, and remote APIs are initialized only when explicitly accessed.
