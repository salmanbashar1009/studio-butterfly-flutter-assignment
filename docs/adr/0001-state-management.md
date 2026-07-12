# ADR 0001: State Management Choice

## Status
Accepted

## Context
The application requires a robust way to handle multi-tenant state, paginated data loading, and complex asynchronous workflows (sending SMS with subsequent aggregate updates). Business logic must be entirely decoupled from the UI to facilitate multi-platform support (Web, Desktop, Mobile) and unit testing.

## Alternatives Considered
1. **Provider**: Simple and standard, but often leads to business logic leaking into the UI layer or "God-objects" if not carefully structured.
2. **Riverpod**: Powerful and modern, but sometimes adds unnecessary complexity for a single-screen dashboard.
3. **GetX**: Rejected due to its reliance on global context and non-standard navigation patterns which make deep testing and tenant isolation harder to enforce.

## Decision
We chose **Flutter BLoC (specifically the Cubit variant)**.

### Why Cubit?
- **Predictable State Transitions**: Every state change is represented by a new immutable state object, making it impossible to have inconsistent UI states.
- **Strict Separation of Concerns**: The `SmsConsoleCubit` contains zero Flutter-specific code (no `BuildContext`), making it portable to any Dart environment.
- **Tenant Isolation**: Cubits make it easy to clear all data explicitly when a tenant changes, preventing memory-resident data leaks.
- **Testing**: Business logic can be verified with `bloc_test` without pumping widgets.

## Consequences
- **Boilerplate**: Slightly more code than `setState` or basic `Provider`, but manageable via IDE snippets.
- **Learning Curve**: Requires understanding of Streams and immutable states.
- **Scalability**: As the app grows, we can easily transition from Cubit to BLoC if complex event-driven logic is required without changing the UI.
