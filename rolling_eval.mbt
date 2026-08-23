///|
fn window_points(
  results : Array[EtaResult],
  actuals : Array[Double],
  start : Int,
  end : Int,
) -> Array[ForecastPoint] {
  let points : Array[ForecastPoint] = []
  let limit = if end > results.length() { results.length() } else { end }
  for index in start..<limit {
    if index >= 0 && index < actuals.length() {
      points.push({
        predicted: results[index].eta_seconds,
        actual: actuals[index],
      })
    }
  }
  points
}

///|
/// Evaluate overlapping rolling windows over ETA results.
pub fn rolling_evaluate(
  results : Array[EtaResult],
  actuals : Array[Double],
  window_size~ : Int,
) -> RollingEvaluation {
  let windows : Array[EvaluationWindow] = []
  let safe_size = if window_size < 1 { 1 } else { window_size }
  let limit = if results.length() < actuals.length() {
    results.length()
  } else {
    actuals.length()
  }
  if limit > 0 {
    for start in 0..<limit {
      let end = if start + safe_size > limit {
        limit
      } else {
        start + safe_size
      }
      let points = window_points(results, actuals, start, end)
      if points.length() > 0 {
        windows.push({ start, end, summary: summarize_errors(points) })
      }
    }
  }
  {
    windows,
    overall: summarize_errors(window_points(results, actuals, 0, limit)),
  }
}

///|
/// Return the worst rolling window by MAE.
pub fn worst_window(evaluation : RollingEvaluation) -> EvaluationWindow? {
  if evaluation.windows.length() == 0 {
    None
  } else {
    let mut worst = evaluation.windows[0]
    for window in evaluation.windows[1:] {
      if window.summary.mae > worst.summary.mae {
        worst = window
      }
    }
    Some(worst)
  }
}

///|
/// Return average MAE across all non-empty rolling windows.
pub fn average_window_mae(evaluation : RollingEvaluation) -> Double {
  let values : Array[Double] = []
  for window in evaluation.windows {
    values.push(window.summary.mae)
  }
  robust_mean(values)
}

///|
/// Render a compact rolling evaluation table.
pub fn format_rolling_evaluation(evaluation : RollingEvaluation) -> String {
  let builder = StringBuilder()
  builder.write_string("rolling windows=\{evaluation.windows.length()}\n")
  for window in evaluation.windows {
    builder.write_string(
      "[\{window.start},\{window.end}) mae=\{window.summary.mae}\n",
    )
  }
  builder.write_string("overall ")
  builder.write_string(format_error_summary(evaluation.overall))
  builder.to_string()
}

///|
/// Compare rolling performance before and after a change.
pub fn rolling_improvement(
  before : RollingEvaluation,
  after : RollingEvaluation,
) -> Double {
  safe_div(before.overall.mae - after.overall.mae, before.overall.mae, 0.0)
}

///|
/// Count windows that satisfy an MAE limit.
pub fn passing_window_count(
  evaluation : RollingEvaluation,
  limit~ : Double,
) -> Int {
  let mut count = 0
  for window in evaluation.windows {
    if window.summary.mae <= limit {
      count += 1
    }
  }
  count
}
