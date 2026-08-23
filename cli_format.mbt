///|
/// Format a route breakdown for CLI output.
pub fn format_breakdown(breakdown : RouteBreakdown) -> String {
  let builder = StringBuilder()
  builder.write_string(
    "route eta=\{breakdown.total_eta_seconds}s distance=\{breakdown.total_distance}m confidence=\{breakdown.confidence}\n",
  )
  for index, segment in breakdown.segments {
    builder.write_string(
      "\{index}: \{segment.segment_id} eta=\{segment.eta_seconds}s speed=\{segment.speed} confidence=\{segment.confidence}\n",
    )
  }
  builder.to_string()
}

///|
/// Format a detailed calendar-aware route forecast.
pub fn format_detailed_breakdown(detailed : DetailedBreakdown) -> String {
  let builder = StringBuilder()
  builder.write_string(
    "weekday={detailed.weekday} second={detailed.second_of_day}\n",
  )
  for forecast in detailed.forecasts {
    builder.write_string(
      "\{forecast.index}: \{forecast.segment.segment_id} congestion=\{forecast.congestion} eta=\{forecast.eta.eta_seconds}\n",
    )
  }
  builder.write_string(format_breakdown(detailed.total))
  builder.to_string()
}

///|
/// Format a batch forecast's headline and trend.
pub fn format_batch_forecast(batch : BatchForecast) -> String {
  let (first, last, delta) = eta_trend(batch)
  "results=\{batch.results.length()} skipped=\{batch.skipped} first=\{first} last=\{last} delta=\{delta} {format_error_summary(batch.summary)}"
}

///|
/// Format a parse result for an import command.
pub fn format_parse_result(result : ObservationParseResult) -> String {
  match result.error {
    None => "parsed=\{result.observations.length()} lines=\{result.lines_read}"
    Some(error) =>
      "parsed=0 lines=\{result.lines_read} error=\{parse_error_code(error)} \{format_parse_error(error)}"
  }
}

///|
/// Format an evaluation window in one line.
pub fn format_evaluation_window(window : EvaluationWindow) -> String {
  "window=[\{window.start},\{window.end}) {format_error_summary(window.summary)}"
}

///|
/// Format calibration candidates in ascending rank order.
pub fn format_grid_calibration(calibration : GridCalibration) -> String {
  let builder = StringBuilder()
  builder.write_string(
    "evaluated=\{calibration.evaluated} best=\{calibration.best.congestion}\n",
  )
  for candidate in calibration.candidates {
    builder.write_string(
      "\{candidate.rank}: congestion=\{candidate.congestion} mae=\{candidate.error.mae}\n",
    )
  }
  builder.to_string()
}
