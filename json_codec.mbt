///|
fn observation_json(observation : Observation) -> Json {
  Json::object({
    "timestamp": Json::number(observation.timestamp),
    "distance": Json::number(observation.distance),
    "elapsed": Json::number(observation.elapsed),
  })
}

///|
fn object_number(object : Map[String, Json], field : String) -> Double? {
  match object.get(field) {
    Some(Json::Number(value, ..)) => Some(value)
    _ => None
  }
}

///|
fn parse_observation_json(
  value : Json,
  line : Int,
) -> ParseOutcome[Observation] {
  match value {
    Json::Object(object) => {
      let timestamp = match object_number(object, "timestamp") {
        None => return ParseFailed(MissingField(line~, field="timestamp"))
        Some(value) => value
      }
      let distance = match object_number(object, "distance") {
        None => return ParseFailed(MissingField(line~, field="distance"))
        Some(value) => value
      }
      let elapsed = match object_number(object, "elapsed") {
        None => return ParseFailed(MissingField(line~, field="elapsed"))
        Some(value) => value
      }
      Parsed({ timestamp, distance, elapsed })
    }
    _ => ParseFailed(InvalidSyntax(line~, message="expected a JSON object"))
  }
}

///|
/// Encode observations as one JSON object per line.
pub fn encode_json_lines(observations : Array[Observation]) -> String {
  let builder = StringBuilder()
  for observation in observations {
    builder.write_string(observation_json(observation).stringify())
    builder.write_char('\n')
  }
  builder.to_string()
}

///|
/// Parse JSON-line observations without aborting on malformed input.
pub fn parse_json_lines(input : String) -> ObservationParseResult {
  if input.trim().is_empty() {
    return parse_error_result(EmptyInput, 0)
  }
  let observations : Array[Observation] = []
  let mut lines_read = 0
  for raw in input.split("\n") {
    let line = raw.trim().to_owned()
    if !line.is_empty() {
      lines_read += 1
      let value = @json.parse(line) catch {
        _ =>
          return parse_error_result(
            InvalidSyntax(line=lines_read, message="invalid JSON"),
            lines_read,
          )
      }
      let parsed = parse_observation_json(value, lines_read)
      match parsed {
        ParseFailed(error) => return parse_error_result(error, lines_read)
        Parsed(observation) => observations.push(observation)
      }
    }
  }
  {
    observations: normalize_observations(observations),
    error: None,
    lines_read,
  }
}

///|
/// Encode a dataset with an optional target field.
pub fn encode_dataset_json_lines(dataset : ObservationDataset) -> String {
  let builder = StringBuilder()
  for row in dataset.rows {
    let object : Map[String, Json] = {
      "timestamp": Json::number(row.observation.timestamp),
      "distance": Json::number(row.observation.distance),
      "elapsed": Json::number(row.observation.elapsed),
      "weight": Json::number(row.weight),
    }
    match row.actual_remaining {
      None => ()
      Some(value) => object["actual_remaining"] = Json::number(value)
    }
    builder.write_string(Json::object(object).stringify())
    builder.write_char('\n')
  }
  builder.to_string()
}

///|
/// Parse JSON lines that optionally contain actual_remaining and weight.
pub fn parse_json_dataset(
  input : String,
  name? : String = "json",
) -> ParseOutcome[ObservationDataset] {
  let parsed = parse_json_lines(input)
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
