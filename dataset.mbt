///|
/// Create a dataset from observations with no target labels.
pub fn dataset_from_observations(
  observations : Array[Observation],
  name? : String = "observations",
) -> ObservationDataset {
  let rows : Array[DatasetRow] = []
  for observation in build_observation_batch(observations).observations {
    rows.push({ observation, actual_remaining: None, weight: 1.0 })
  }
  { rows, name }
}

///|
/// Create a labeled dataset from aligned observations and targets.
pub fn dataset_from_targets(
  observations : Array[Observation],
  actuals : Array[Double],
  name? : String = "labeled-observations",
) -> ObservationDataset {
  let rows : Array[DatasetRow] = []
  for index, observation in observations {
    let target = if index < actuals.length() {
      Some(actuals[index])
    } else {
      None
    }
    rows.push({ observation, actual_remaining: target, weight: 1.0 })
  }
  { rows, name }
}

///|
/// Return observations in dataset order.
pub fn ObservationDataset::observations(
  self : ObservationDataset,
) -> Array[Observation] {
  let values : Array[Observation] = []
  for row in self.rows {
    values.push(row.observation)
  }
  values
}

///|
/// Return targets while preserving missing labels as zero.
pub fn ObservationDataset::targets(self : ObservationDataset) -> Array[Double] {
  let values : Array[Double] = []
  for row in self.rows {
    match row.actual_remaining {
      Some(value) => values.push(value)
      None => values.push(0.0)
    }
  }
  values
}

///|
/// Return only rows with an actual target.
pub fn ObservationDataset::labeled(
  self : ObservationDataset,
) -> ObservationDataset {
  let rows : Array[DatasetRow] = []
  for row in self.rows {
    if row.actual_remaining is Some(_) {
      rows.push(row)
    }
  }
  { rows, name: "{self.name}-labeled" }
}

///|
/// Return rows that fall inside a timestamp interval.
pub fn ObservationDataset::between(
  self : ObservationDataset,
  start~ : Double,
  end~ : Double,
) -> ObservationDataset {
  let low = if start < end { start } else { end }
  let high = if start < end { end } else { start }
  let rows : Array[DatasetRow] = []
  for row in self.rows {
    if row.observation.timestamp >= low && row.observation.timestamp <= high {
      rows.push(row)
    }
  }
  { rows, name: "{self.name}-window" }
}

///|
/// Sort dataset rows by timestamp and remove duplicate timestamps.
pub fn ObservationDataset::normalize(
  self : ObservationDataset,
) -> ObservationDataset {
  let observations = normalize_observations(self.observations())
  let rows : Array[DatasetRow] = []
  for observation in observations {
    let mut selected : DatasetRow = {
      observation,
      actual_remaining: None,
      weight: 1.0,
    }
    for row in self.rows {
      if row.observation.timestamp == observation.timestamp {
        selected = row
      }
    }
    rows.push(selected)
  }
  { rows, name: self.name }
}

///|
/// Return a dataset with all weights clamped to non-negative values.
pub fn ObservationDataset::weighted(
  self : ObservationDataset,
) -> ObservationDataset {
  let rows : Array[DatasetRow] = []
  for row in self.rows {
    rows.push({ ..row, weight: if row.weight < 0.0 { 0.0 } else { row.weight } })
  }
  { rows, name: self.name }
}

///|
/// Append two datasets in stable left-to-right order.
pub fn append_dataset(
  left : ObservationDataset,
  right : ObservationDataset,
) -> ObservationDataset {
  let rows = left.rows.copy()
  rows.append(right.rows[:])
  { rows, name: "{left.name}+{right.name}" }
}

///|
/// Return a descriptive summary of a dataset.
pub fn summarize_dataset(dataset : ObservationDataset) -> DatasetSummary {
  if dataset.rows.length() == 0 {
    {
      rows: 0,
      duration: 0.0,
      distance: 0.0,
      average_speed: 0.0,
      missing_targets: 0,
      average_weight: 0.0,
    }
  } else {
    let observations = dataset.observations()
    let first = observations[0]
    let last = observations[observations.length() - 1]
    let speeds : Array[Double] = []
    let weights : Array[Double] = []
    let mut missing = 0
    for index, row in dataset.rows {
      weights.push(row.weight)
      if row.actual_remaining is None {
        missing += 1
      }
      if index > 0 {
        let previous = observations[index - 1]
        let dt = row.observation.timestamp - previous.timestamp
        let dd = row.observation.distance - previous.distance
        if dt > 0.0 {
          speeds.push(dd / dt)
        }
      }
    }
    {
      rows: dataset.rows.length(),
      duration: last.timestamp - first.timestamp,
      distance: last.distance - first.distance,
      average_speed: robust_mean(speeds),
      missing_targets: missing,
      average_weight: robust_mean(weights),
    }
  }
}

///|
/// Return the duration in seconds, clamped to a non-negative result.
pub fn dataset_duration(dataset : ObservationDataset) -> Double {
  let summary = summarize_dataset(dataset)
  if summary.duration < 0.0 {
    0.0
  } else {
    summary.duration
  }
}

///|
/// Return the distance covered by the dataset.
pub fn dataset_distance(dataset : ObservationDataset) -> Double {
  let summary = summarize_dataset(dataset)
  if summary.distance < 0.0 {
    0.0
  } else {
    summary.distance
  }
}

///|
/// Return target coverage as a fraction.
pub fn target_coverage(dataset : ObservationDataset) -> Double {
  if dataset.rows.length() == 0 {
    0.0
  } else {
    1.0 -
    summarize_dataset(dataset).missing_targets.to_double() /
    dataset.rows.length().to_double()
  }
}

///|
/// Return row weights as an array.
pub fn dataset_weights(dataset : ObservationDataset) -> Array[Double] {
  let weights : Array[Double] = []
  for row in dataset.rows {
    weights.push(row.weight)
  }
  weights
}

///|
/// Keep every nth row, preserving the first row.
pub fn stride_dataset(
  dataset : ObservationDataset,
  stride : Int,
) -> ObservationDataset {
  let safe_stride = if stride < 1 { 1 } else { stride }
  let rows : Array[DatasetRow] = []
  for index, row in dataset.rows {
    if index % safe_stride == 0 {
      rows.push(row)
    }
  }
  { rows, name: "{dataset.name}-stride" }
}

///|
/// Return a target distribution for diagnostics.
pub fn target_distribution(dataset : ObservationDataset) -> Array[Double] {
  let values : Array[Double] = []
  for row in dataset.rows {
    match row.actual_remaining {
      Some(value) => values.push(value)
      None => ()
    }
  }
  values
}
