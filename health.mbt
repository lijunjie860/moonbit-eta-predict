///|
/// Validate all runtime inputs required by the ETA facade.
pub fn health_check(
  route : RouteProfile,
  config? : EtaConfig = default_eta_config(),
  calendar? : RouteCalendar = demo_calendar(),
) -> HealthReport {
  let messages : Array[String] = []
  let route_valid = validate_route(route).valid
  let config_valid = validate_eta_config(config).valid
  let calendar_valid = calendar.days.all(day => {
    day.valid_bucket_count() == day.buckets.length()
  })
  if !route_valid {
    messages.push("route parameters are invalid")
  }
  if !config_valid {
    messages.push("ETA configuration is invalid")
  }
  if !calendar_valid {
    messages.push("calendar contains invalid buckets")
  }
  {
    ready: route_valid && config_valid && calendar_valid,
    route_valid,
    config_valid,
    calendar_valid,
    messages,
  }
}

///|
/// Return stable package capabilities for a host application.
pub fn capabilities() -> Array[String] {
  [
    "streaming-kalman", "adaptive-window", "route-calendar", "csv-codec", "json-lines-codec",
    "batch-calibration", "deterministic-benchmarks", "all-target-tests",
  ]
}

///|
/// Return whether all advertised capabilities are non-empty.
pub fn capabilities_are_named() -> Bool {
  capabilities().all(name => !name.trim().is_empty())
}

///|
/// Return a health summary for the reference route.
pub fn demo_health() -> HealthReport {
  health_check(demo_route())
}

///|
/// Render health status for CLI output.
pub fn format_health(report : HealthReport) -> String {
  let status = if report.ready { "ready" } else { "not-ready" }
  "status=\{status} route=\{report.route_valid} config=\{report.config_valid} calendar=\{report.calendar_valid} messages=\{report.messages.length()}"
}
