///|
/// Public package version shown by the CLI and release tooling.
pub fn package_version() -> String {
  "0.2.2"
}

///|
/// Human-readable package title.
pub fn package_name() -> String {
  "moonbit-eta-predict"
}

///|
/// Package purpose for generated metadata and host integrations.
pub fn package_description() -> String {
  "Deterministic streaming ETA prediction primitives for MoonBit"
}

///|
/// License identifier used by the module metadata.
pub fn package_license() -> String {
  "Apache-2.0"
}

///|
/// Repository URL for diagnostics and generated reports.
pub fn package_repository() -> String {
  "https://github.com/lijunjie860/moonbit-eta-predict"
}

///|
/// Runtime targets exercised by the library design.
pub fn supported_targets() -> Array[String] {
  ["wasm-gc", "wasm", "js", "native", "llvm"]
}

///|
/// Return whether a target is supported by the package contract.
pub fn supports_target(target : String) -> Bool {
  supported_targets().contains(target.trim().to_owned().to_lower())
}

///|
/// Public feature names used in release notes and package discovery.
pub fn feature_names() -> Array[String] {
  [
    "kalman-smoothing", "innovation-gating", "adaptive-windows", "route-profiles",
    "calendar-congestion", "csv-and-json-lines", "batch-calibration", "rolling-evaluation",
    "deterministic-benchmarks", "quality-gates",
  ]
}

///|
/// Return a stable release metadata block.
pub fn release_metadata() -> String {
  let builder = StringBuilder()
  builder.write_string("name=")
  builder.write_string(package_name())
  builder.write_char('\n')
  builder.write_string("version=")
  builder.write_string(package_version())
  builder.write_char('\n')
  builder.write_string("license=")
  builder.write_string(package_license())
  builder.write_char('\n')
  builder.write_string("targets=")
  builder.write_string(supported_targets().join(","))
  builder.write_char('\n')
  builder.write_string("features=")
  builder.write_string(feature_names().join(","))
  builder.to_string()
}

///|
/// Check the public metadata contract.
pub fn metadata_is_complete() -> Bool {
  !package_name().is_empty() &&
  !package_version().is_empty() &&
  package_license() == "Apache-2.0" &&
  supports_target("wasm-gc") &&
  feature_names().length() >= 8
}

///|
/// Return a concise version string for command output.
pub fn version_banner() -> String {
  "\{package_name()} \{package_version()} (\{package_license()})"
}

///|
/// Return the expected generated interface filename for the root package.
pub fn interface_filename() -> String {
  "pkg.generated.mbti"
}

///|
/// Return the recommended validation commands as data.
pub fn validation_commands() -> Array[String] {
  [
    "moon fmt --check", "moon check --deny-warn --target all", "moon test --deny-warn --target all",
    "moon info", "moon publish",
  ]
}
