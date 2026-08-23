///|
/// Detect operational alerts in a stream summary.
pub fn detect_alerts(
  summary : StreamSummary,
  confidence_threshold? : Double = 0.2,
  eta_jump_threshold? : Double = 120.0,
) -> Array[ForecastAlert] {
  let alerts : Array[ForecastAlert] = []
  let confidence_limit = clamp(confidence_threshold, 0.0, 1.0)
  let jump_limit = abs_double(eta_jump_threshold)
  let mut previous_eta = -1.0
  for snapshot in summary.snapshots {
    if snapshot.result.confidence < confidence_limit {
      alerts.push({
        kind: LowConfidence,
        update: snapshot.update,
        severity: clamp(confidence_limit - snapshot.result.confidence, 0.0, 1.0),
        message: "confidence below operating threshold",
      })
    }
    if previous_eta >= 0.0 &&
      abs_double(snapshot.result.eta_seconds - previous_eta) > jump_limit {
      alerts.push({
        kind: EtaJump,
        update: snapshot.update,
        severity: clamp(
          abs_double(snapshot.result.eta_seconds - previous_eta) /
          (jump_limit + 0.0001),
          0.0,
          1.0,
        ),
        message: "ETA changed sharply between updates",
      })
    }
    if snapshot.result.remaining_distance > 0.0 &&
      snapshot.result.smoothed_speed <= 0.5 {
      alerts.push({
        kind: StalledProgress,
        update: snapshot.update,
        severity: 1.0,
        message: "progress appears stalled",
      })
    }
    if snapshot.result.remaining_distance <= 0.0 {
      alerts.push({
        kind: RouteComplete,
        update: snapshot.update,
        severity: 0.0,
        message: "route is complete",
      })
    }
    previous_eta = snapshot.result.eta_seconds
  }
  alerts
}

///|
/// Return alert counts by kind in a fixed order.
pub fn alert_counts(alerts : Array[ForecastAlert]) -> Array[Int] {
  let counts = [0, 0, 0, 0, 0]
  for alert in alerts {
    let index = match alert.kind {
      LowConfidence => 0
      EtaJump => 1
      StalledProgress => 2
      RouteComplete => 3
      InvalidObservation => 4
    }
    counts[index] += 1
  }
  counts
}

///|
/// Return the highest-severity alert.
pub fn highest_alert(alerts : Array[ForecastAlert]) -> ForecastAlert? {
  if alerts.length() == 0 {
    None
  } else {
    let mut highest = alerts[0]
    for alert in alerts[1:] {
      if alert.severity > highest.severity {
        highest = alert
      }
    }
    Some(highest)
  }
}

///|
/// Render alerts for a log line.
pub fn format_alert(alert : ForecastAlert) -> String {
  let kind = match alert.kind {
    LowConfidence => "low_confidence"
    EtaJump => "eta_jump"
    StalledProgress => "stalled_progress"
    RouteComplete => "route_complete"
    InvalidObservation => "invalid_observation"
  }
  "\{kind} update=\{alert.update} severity=\{alert.severity} \{alert.message}"
}

///|
/// Render every alert on its own line.
pub fn format_alerts(alerts : Array[ForecastAlert]) -> String {
  let builder = StringBuilder()
  for alert in alerts {
    builder.write_string("\{format_alert(alert)}\n")
  }
  builder.to_string()
}

///|
/// Return whether alerts contain a hard operational fault.
fn hard_alert_kind(kind : AlertKind) -> Bool {
  match kind {
    InvalidObservation => true
    StalledProgress => true
    _ => false
  }
}

///|
/// Return whether alerts contain a hard operational fault.
pub fn has_hard_alert(alerts : Array[ForecastAlert]) -> Bool {
  alerts.any(alert => hard_alert_kind(alert.kind))
}

///|
/// Return a route stream summary augmented with invalid-input alerts.
pub fn monitor_observations(
  observations : Array[Observation],
  route : RouteProfile,
) -> (StreamSummary, Array[ForecastAlert]) {
  let summary = replay_stream(observations, route)
  let alerts = detect_alerts(summary)
  let mut previous_time = -1.0
  for observation in observations {
    if observation.timestamp < 0.0 ||
      observation.timestamp < previous_time ||
      observation.distance < 0.0 {
      alerts.push({
        kind: InvalidObservation,
        update: 0,
        severity: 1.0,
        message: "observation rejected by monitor",
      })
    }
    previous_time = observation.timestamp
  }
  (summary, alerts)
}
