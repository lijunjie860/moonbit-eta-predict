///|
/// Return whether parsing succeeded.
pub fn ObservationParseResult::is_error(self : ObservationParseResult) -> Bool {
  self.error is Some(_)
}

///|
/// Return the parsed observations, or an empty array after an error.
pub fn ObservationParseResult::or_empty(
  self : ObservationParseResult,
) -> Array[Observation] {
  self.observations
}

///|
/// Render a parse error for CLI and logs.
pub fn format_parse_error(error : ParseError) -> String {
  match error {
    EmptyInput => "input is empty"
    MissingHeader => "CSV header is missing"
    MissingField(line~, field~) => "line \{line}: missing field \{field}"
    ExtraField(line~) => "line \{line}: extra field"
    InvalidNumber(line~, field~, value~) =>
      "line \{line}: invalid number in \{field}: \{value}"
    InvalidSyntax(line~, message~) => "line \{line}: invalid syntax: \{message}"
    UnsupportedSchema(message) => "unsupported schema: \{message}"
  }
}

///|
/// Return a compact error code suitable for machine-readable reports.
pub fn parse_error_code(error : ParseError) -> String {
  match error {
    EmptyInput => "empty_input"
    MissingHeader => "missing_header"
    MissingField(..) => "missing_field"
    ExtraField(_) => "extra_field"
    InvalidNumber(..) => "invalid_number"
    InvalidSyntax(..) => "invalid_syntax"
    UnsupportedSchema(_) => "unsupported_schema"
  }
}

///|
/// Convert a JSON number string into a Double without panicking.
pub fn parse_double_token(token : String) -> Double? {
  let parsed = @json.parse(token) catch { _ => return None }
  match parsed {
    Json::Number(value, ..) => Some(value)
    _ => None
  }
}

///|
fn parse_error_result(
  error : ParseError,
  lines_read : Int,
) -> ObservationParseResult {
  { observations: [], error: Some(error), lines_read }
}
