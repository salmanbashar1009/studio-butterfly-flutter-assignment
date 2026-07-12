/// Developer-only enumeration for controlling the [FakeSmsRepository] behaviour.
///
/// Lives in `utils/` so it can be imported by both the data layer
/// (`FakeSmsRepository`) and the presentation layer (`SmsConsoleState`)
/// without creating a dependency-inversion violation — neither the data
/// layer imports the presentation layer, nor the presentation layer imports
/// the data layer.
enum DevServerMode {
  success,
  empty,
  networkFailure,
  timeout,
  serverError,
  rateLimit429,
}
