///|
pub fn format_eta_result(result : EtaResult) -> String {
  "eta=\{result.eta_seconds}s speed=\{result.smoothed_speed}m/s confidence=\{result.confidence}"
}

///|
pub fn format_error_summary(summary : ErrorSummary) -> String {
  "count=\{summary.count} mae=\{summary.mae} rmse=\{summary.rmse} mape=\{summary.mape} max=\{summary.max_error}"
}

///|
pub fn format_calibration(result : CalibrationResult) -> String {
  "best_congestion=\{result.best_congestion} \{format_error_summary(result.best_error)}"
}

///|
pub fn demo_report() -> String {
  let results = run_demo()
  let last = if results.length() == 0 {
    {
      eta_seconds: 0.0,
      smoothed_speed: 0.0,
      raw_speed: 0.0,
      confidence: 0.0,
      remaining_distance: 0.0,
    }
  } else {
    results[results.length() - 1]
  }
  let calibration = calibrate_demo()
  "MoonBit ETA report\n\{format_eta_result(last)}\n\{format_calibration(calibration)}"
}
