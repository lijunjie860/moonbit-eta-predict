///|
/// Initialize a route stream with a calendar-aware ETA engine.
pub fn RouteStreamState::new(
  route : RouteProfile,
  initial_speed~ : Double,
  calendar? : RouteCalendar = demo_calendar(),
  weekday? : Int = 0,
  second_of_day? : Double = 8.0 * 3600.0,
) -> RouteStreamState {
  {
    route,
    engine: EtaEngine::new(route, initial_speed~),
    calendar,
    weekday: normalize_weekday(weekday),
    second_of_day: clamp(second_of_day, 0.0, 86400.0),
    updates: 0,
  }
}

///|
/// Apply one observation and retain the next stream state.
pub fn RouteStreamState::observe(
  self : RouteStreamState,
  observation : Observation,
) -> (RouteStreamState, StreamSnapshot) {
  let congestion = self.calendar.congestion_at(self.weekday, self.second_of_day)
  let (engine, result) = self.engine.observe(observation, congestion~)
  let next = {
    ..self,
    engine,
    second_of_day: self.second_of_day + max_double(observation.elapsed, 0.0),
    updates: self.updates + 1,
  }
  let label = calendar_label(self.calendar, self.weekday, self.second_of_day)
  (next, { update: next.updates, observation, result, label })
}

///|
fn max_double(left : Double, right : Double) -> Double {
  if left > right {
    left
  } else {
    right
  }
}

///|
/// Replay a trace through a calendar-aware stream.
pub fn replay_stream(
  observations : Array[Observation],
  route : RouteProfile,
  initial_speed? : Double = 8.0,
) -> StreamSummary {
  let snapshots : Array[StreamSnapshot] = []
  let mut stream = RouteStreamState::new(route, initial_speed~)
  let mut dropped = 0
  for observation in observations {
    if observation.timestamp < 0.0 || observation.distance < 0.0 {
      dropped += 1
    } else {
      let (next, snapshot) = stream.observe(observation)
      stream = next
      snapshots.push(snapshot)
    }
  }
  let latest = if snapshots.length() == 0 {
    {
      eta_seconds: 0.0,
      smoothed_speed: 0.0,
      raw_speed: 0.0,
      confidence: 0.0,
      remaining_distance: 0.0,
    }
  } else {
    snapshots[snapshots.length() - 1].result
  }
  let confidences : Array[Double] = []
  for snapshot in snapshots {
    confidences.push(snapshot.result.confidence)
  }
  { snapshots, latest, average_confidence: robust_mean(confidences), dropped }
}

///|
/// Return ETA values from stream snapshots.
pub fn snapshot_etas(summary : StreamSummary) -> Array[Double] {
  let values : Array[Double] = []
  for snapshot in summary.snapshots {
    values.push(snapshot.result.eta_seconds)
  }
  values
}

///|
/// Return confidence values from stream snapshots.
pub fn snapshot_confidences(summary : StreamSummary) -> Array[Double] {
  let values : Array[Double] = []
  for snapshot in summary.snapshots {
    values.push(snapshot.result.confidence)
  }
  values
}

///|
/// Return whether stream ETAs are non-negative and finite.
pub fn stream_is_safe(summary : StreamSummary) -> Bool {
  let mut safe = true
  for snapshot in summary.snapshots {
    if snapshot.result.eta_seconds < 0.0 ||
      !is_finite_value(snapshot.result.eta_seconds) {
      safe = false
    }
  }
  safe
}

///|
/// Return the latest label, or `none` for an empty stream.
pub fn latest_stream_label(summary : StreamSummary) -> String {
  if summary.snapshots.length() == 0 {
    "none"
  } else {
    summary.snapshots[summary.snapshots.length() - 1].label
  }
}

///|
/// Return the number of updates with confidence below a threshold.
pub fn low_confidence_updates(
  summary : StreamSummary,
  threshold~ : Double,
) -> Int {
  let mut count = 0
  for snapshot in summary.snapshots {
    if snapshot.result.confidence < threshold {
      count += 1
    }
  }
  count
}

///|
/// Merge two stream summaries in temporal order.
pub fn merge_stream_summaries(
  left : StreamSummary,
  right : StreamSummary,
) -> StreamSummary {
  let snapshots = left.snapshots.copy()
  snapshots.append(right.snapshots[:])
  let confidences : Array[Double] = []
  for snapshot in snapshots {
    confidences.push(snapshot.result.confidence)
  }
  let latest = if snapshots.length() == 0 {
    left.latest
  } else {
    snapshots[snapshots.length() - 1].result
  }
  {
    snapshots,
    latest,
    average_confidence: robust_mean(confidences),
    dropped: left.dropped + right.dropped,
  }
}

///|
/// Split a stream summary into fixed-size pages for a dashboard.
pub fn page_stream(
  summary : StreamSummary,
  page_size : Int,
) -> Array[StreamSummary] {
  let pages : Array[StreamSummary] = []
  let size = if page_size < 1 { 1 } else { page_size }
  for start in 0..<summary.snapshots.length() {
    if start % size == 0 {
      let end = if start + size > summary.snapshots.length() {
        summary.snapshots.length()
      } else {
        start + size
      }
      let snapshots : Array[StreamSnapshot] = []
      for index in start..<end {
        snapshots.push(summary.snapshots[index])
      }
      let latest = if snapshots.length() == 0 {
        summary.latest
      } else {
        snapshots[snapshots.length() - 1].result
      }
      let values : Array[Double] = []
      for snapshot in snapshots {
        values.push(snapshot.result.confidence)
      }
      pages.push({
        snapshots,
        latest,
        average_confidence: robust_mean(values),
        dropped: 0,
      })
    }
  }
  pages
}
