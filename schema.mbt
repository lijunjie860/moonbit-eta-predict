///|
/// The canonical observation schema.
pub fn observation_schema() -> DatasetSchema {
  {
    name: "observation",
    required: [Timestamp, Distance, Elapsed],
    optional: [ActualRemaining, Weight],
    version: "1",
  }
}

///|
/// The schema used for labeled evaluation datasets.
pub fn labeled_schema() -> DatasetSchema {
  {
    name: "labeled-observation",
    required: [Timestamp, Distance, Elapsed, ActualRemaining],
    optional: [Weight],
    version: "1",
  }
}

///|
/// Convert a schema field into its wire name.
pub fn schema_field_name(field : SchemaField) -> String {
  match field {
    Timestamp => "timestamp"
    Distance => "distance"
    Elapsed => "elapsed"
    ActualRemaining => "actual_remaining"
    Weight => "weight"
  }
}

///|
/// Parse a schema field name.
pub fn schema_field_from_name(name : String) -> SchemaField? {
  let normalized = name.trim().to_owned().to_lower()
  if normalized == "timestamp" {
    Some(Timestamp)
  } else if normalized == "distance" {
    Some(Distance)
  } else if normalized == "elapsed" {
    Some(Elapsed)
  } else if normalized == "actual_remaining" {
    Some(ActualRemaining)
  } else if normalized == "weight" {
    Some(Weight)
  } else {
    None
  }
}

///|
/// Return all supported field names in canonical order.
pub fn all_schema_field_names() -> Array[String] {
  ["timestamp", "distance", "elapsed", "actual_remaining", "weight"]
}

///|
/// Check a header against a schema.
pub fn validate_schema_header(
  schema : DatasetSchema,
  headers : Array[String],
) -> SchemaReport {
  let fields : Array[SchemaField] = []
  let unknown : Array[String] = []
  for header in headers {
    match schema_field_from_name(header) {
      Some(field) => fields.push(field)
      None => unknown.push(header)
    }
  }
  let missing : Array[SchemaField] = []
  for required in schema.required {
    if !fields.contains(required) {
      missing.push(required)
    }
  }
  let valid = missing.length() == 0 && unknown.length() == 0
  let message = if valid {
    "schema accepted"
  } else if missing.length() > 0 {
    "required fields are missing"
  } else {
    "unknown fields are present"
  }
  { valid, missing, unknown, message }
}

///|
/// Return whether a field is accepted by the schema.
pub fn DatasetSchema::accepts(
  self : DatasetSchema,
  field : SchemaField,
) -> Bool {
  self.required.contains(field) || self.optional.contains(field)
}

///|
/// Return the number of fields in a schema.
pub fn DatasetSchema::field_count(self : DatasetSchema) -> Int {
  self.required.length() + self.optional.length()
}

///|
/// Render a stable schema description.
pub fn format_schema(schema : DatasetSchema) -> String {
  let required = schema.required.map(schema_field_name).join(",")
  let optional = schema.optional.map(schema_field_name).join(",")
  "\{schema.name}@\{schema.version} required=[\{required}] optional=[\{optional}]"
}

///|
/// Return canonical CSV headers for a schema.
pub fn schema_headers(
  schema : DatasetSchema,
  include_optional? : Bool = false,
) -> Array[String] {
  let headers : Array[String] = []
  for field in schema.required {
    headers.push(schema_field_name(field))
  }
  if include_optional {
    for field in schema.optional {
      headers.push(schema_field_name(field))
    }
  }
  headers
}

///|
/// Check whether a field list has duplicates.
pub fn has_duplicate_fields(fields : Array[String]) -> Bool {
  for index, field in fields {
    for other in (index + 1)..<fields.length() {
      if field.trim().to_owned().to_lower() ==
        fields[other].trim().to_owned().to_lower() {
        return true
      }
    }
  }
  false
}

///|
/// Validate a dataset schema name and version.
pub fn validate_schema_metadata(schema : DatasetSchema) -> Bool {
  !schema.name.trim().is_empty() &&
  !schema.version.trim().is_empty() &&
  schema.required.length() > 0 &&
  !has_duplicate_fields(schema_headers(schema, include_optional=true))
}
