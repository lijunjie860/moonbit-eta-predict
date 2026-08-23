///|
fn split_csv_line(line : String) -> ParseOutcome[Array[String]] {
  let fields : Array[String] = []
  let mut current = StringBuilder()
  let mut quoted = false
  let mut escaped = false
  for char in line {
    if escaped {
      current.write_char(char)
      escaped = false
    } else if char == '\\' && quoted {
      escaped = true
    } else if char == '"' {
      quoted = !quoted
    } else if char == ',' && !quoted {
      fields.push(current.to_string())
      current = StringBuilder()
    } else {
      current.write_char(char)
    }
  }
  if quoted || escaped {
    ParseFailed(InvalidSyntax(line=0, message="unterminated CSV quote"))
  } else {
    fields.push(current.to_string())
    Parsed(fields)
  }
}

///|
fn csv_header_index(headers : Array[String], name : String) -> Int? {
  for index, header in headers {
    if header.trim().to_owned() == name {
      return Some(index)
    }
  }
  None
}

///|
fn token_at(fields : Array[String], index : Int) -> String? {
  if index < 0 || index >= fields.length() {
    None
  } else {
    Some(fields[index].trim().to_owned())
  }
}

///|
fn parse_csv_number(
  fields : Array[String],
  index : Int,
  line : Int,
  field : String,
) -> ParseOutcome[Double] {
  match token_at(fields, index) {
    None => ParseFailed(MissingField(line~, field~))
    Some(token) =>
      match parse_double_token(token) {
        None => ParseFailed(InvalidNumber(line~, field~, value=token))
        Some(value) => Parsed(value)
      }
  }
}

///|
fn parse_csv_row(
  fields : Array[String],
  line : Int,
  timestamp_index : Int,
  distance_index : Int,
  elapsed_index : Int,
) -> ParseOutcome[Observation] {
  let timestamp = match
    parse_csv_number(fields, timestamp_index, line, "timestamp") {
    Parsed(value) => value
    ParseFailed(error) => return ParseFailed(error)
  }
  let distance = match
    parse_csv_number(fields, distance_index, line, "distance") {
    Parsed(value) => value
    ParseFailed(error) => return ParseFailed(error)
  }
  let elapsed = match parse_csv_number(fields, elapsed_index, line, "elapsed") {
    Parsed(value) => value
    ParseFailed(error) => return ParseFailed(error)
  }
  Parsed({ timestamp, distance, elapsed })
}

///|
/// Parse a CSV document with a required timestamp/distance/elapsed header.
pub fn parse_csv_observations(csv : String) -> ObservationParseResult {
  if csv.trim().is_empty() {
    return parse_error_result(EmptyInput, 0)
  }
  let lines : Array[String] = []
  for raw in csv.split("\n") {
    let line = raw.trim_end(chars="\r").to_owned()
    if !line.trim().is_empty() {
      lines.push(line)
    }
  }
  if lines.length() == 0 {
    return parse_error_result(EmptyInput, 0)
  }
  let header = match split_csv_line(lines[0]) {
    ParseFailed(error) => return parse_error_result(error, 1)
    Parsed(fields) => fields.map(field => field.trim().to_owned().to_lower())
  }
  let timestamp_index = match csv_header_index(header, "timestamp") {
    None =>
      return parse_error_result(MissingField(line=1, field="timestamp"), 1)
    Some(index) => index
  }
  let distance_index = match csv_header_index(header, "distance") {
    None => return parse_error_result(MissingField(line=1, field="distance"), 1)
    Some(index) => index
  }
  let elapsed_index = match csv_header_index(header, "elapsed") {
    None => return parse_error_result(MissingField(line=1, field="elapsed"), 1)
    Some(index) => index
  }
  let observations : Array[Observation] = []
  for line_index in 1..<lines.length() {
    match split_csv_line(lines[line_index]) {
      ParseFailed(error) => return parse_error_result(error, line_index + 1)
      Parsed(fields) => {
        if fields.length() < header.length() {
          return parse_error_result(
            ExtraField(line=line_index + 1),
            line_index + 1,
          )
        }
        match
          parse_csv_row(
            fields,
            line_index + 1,
            timestamp_index,
            distance_index,
            elapsed_index,
          ) {
          ParseFailed(error) => return parse_error_result(error, line_index + 1)
          Parsed(observation) => observations.push(observation)
        }
      }
    }
  }
  {
    observations: normalize_observations(observations),
    error: None,
    lines_read: lines.length(),
  }
}

///|
/// Encode observations as a portable CSV document.
pub fn encode_csv_observations(observations : Array[Observation]) -> String {
  let builder = StringBuilder()
  builder.write_string("timestamp,distance,elapsed\n")
  for observation in observations {
    builder.write_string(
      "\{observation.timestamp},\{observation.distance},\{observation.elapsed}\n",
    )
  }
  builder.to_string()
}

///|
/// Parse a CSV document into a dataset with optional target columns.
pub fn parse_csv_dataset(
  csv : String,
  name? : String = "csv",
) -> ParseOutcome[ObservationDataset] {
  let parsed = parse_csv_observations(csv)
  match parsed.error {
    Some(error) => ParseFailed(error)
    None => {
      let rows : Array[DatasetRow] = []
      for observation in parsed.observations {
        rows.push({ observation, actual_remaining: None, weight: 1.0 })
      }
      Parsed({ rows, name })
    }
  }
}
