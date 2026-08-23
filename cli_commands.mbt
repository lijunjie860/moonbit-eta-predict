///|
/// The public command dispatcher used by the demo executable and tests.
pub fn run_cli(arguments : Array[String]) -> String {
  match arguments {
    [] => cli_help()
    ["help"] => cli_help()
    ["--help"] => cli_help()
    ["version"] => version_banner()
    ["demo"] => demo_report()
    ["benchmark"] => benchmark_annotation(run_benchmark_suite())
    ["benchmark", "table"] => render_benchmark_table(run_benchmark_suite())
    ["calibrate"] => format_calibration(calibrate_demo())
    ["validate"] =>
      format_validation(validate_observations(demo_observations()))
    [command, ..] => "unknown command: \{command}"
  }
}

///|
/// Render the command list.
pub fn cli_help() -> String {
  "moonbit-eta-predict commands:\n  demo\n  benchmark [table]\n  calibrate\n  validate\n  version\n  help"
}

///|
/// Render validation findings.
pub fn format_validation(report : ValidationReport) -> String {
  let builder = StringBuilder()
  builder.write_string(
    "valid=\{report.valid} checked=\{report.checked} issues=\{report.issues.length()}\n",
  )
  for finding in report.issues {
    builder.write_string("\{finding.index}: \{finding.message}\n")
  }
  builder.to_string()
}

///|
/// Parse a minimal key=value command option list.
pub fn parse_cli_options(arguments : Array[String]) -> Map[String, String] {
  let options : Map[String, String] = Map([])
  for argument in arguments {
    match argument.split_once("=") {
      Some((key, value)) => options[key.to_owned()] = value.to_owned()
      None => options[argument] = "true"
    }
  }
  options
}

///|
/// Render a route summary for command output.
pub fn route_summary(route : RouteProfile) -> String {
  "segments=\{route.segments.length()} distance=\{route.total_distance()} reliability=\{route.average_reliability()}"
}

///|
/// Run the benchmark and return the full evidence block.
pub fn run_cli_benchmark() -> String {
  benchmark_evidence(run_benchmark_suite(), "moon run cmd/main -- benchmark")
}
