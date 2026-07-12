# AI Usage Disclosure

## How AI was Used
In this project, AI (Claude 3.7 Sonnet) was used as a primary pair programmer and reviewer. It was used to:
- Perform the initial security and code audit of the starter file.
- Scaffold the Clean Architecture folder structure.
- Generate repetitive boilerplate for immutable state classes and factory constructors.
- Draft the base unit tests for the Money utility.

## Where the AI was Wrong
- **Money Handling**: In an initial draft, the AI suggested using the `decimal` package. While technically correct, I rejected this to avoid external dependencies for a core domain concept, instead opting for a custom integer-based `Money` class to demonstrate deep understanding of the underlying precision issues.
- **Tenant Isolation**: The AI initially forgot to clear the `messages` list when switching tenants in the Cubit, which would have lead to a "flicker" where one tenant's data was visible for a few milliseconds while the new tenant's data was loading. I manually added the state reset logic.
- **Error Mapping**: The AI initially lumped all HTTP errors into a generic `SmsException`. I rewrote the data layer to map specific status codes (429, 502, 403) to semantic domain exceptions (`SmsRateLimitException`, etc.) so the UI could show specific recovery paths (e.g., a countdown for 429).

## Manual Engineering Judgment
- **Design System**: I manually defined the spacing and color palette in `app_theme.dart` to ensure it felt like a cohesive "Formwork" product rather than a generic Material demo.
- **Responsive Strategy**: I chose a `LayoutBuilder` with a hard breakpoint at 900px. I rejected `AdaptiveBreakpoints` packages to keep the codebase lean and demonstrate `CustomScrollView` and `flex` layouts.
- **Status Transitions**: I manually implemented the `Timer` logic in the `FakeSmsRepository` to simulate the asynchronous nature of SMS delivery (`ACCEPTED -> SENT -> DELIVERED`), as the AI's first draft of the mock was too static.

## Deliberate Rejections
- **AI-Suggested Global State**: The AI suggested a `ChangeNotifier` approach for speed. I rejected this in favor of `Cubit` to enforce stricter state boundaries and easier testability for multi-tenancy.
- **Hardcoded API Keys**: Even though the starter had them, and the AI occasionally "hallucinated" that they were okay for a demo, I strictly moved them to a constructor-injected pattern.
