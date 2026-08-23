///|
/// Mean signed forecast error; positive values indicate over-prediction.
pub fn forecast_bias(points : Array[ForecastPoint]) -> Double {
  if points.length() == 0 {
    0.0
  } else {
    let errors : Array[Double] = []
    for point in points {
      errors.push(point.predicted - point.actual)
    }
    robust_mean(errors)
  }
}

///|
/// Symmetric mean absolute percentage error.
pub fn smape(points : Array[ForecastPoint]) -> Double {
  if points.length() == 0 {
    0.0
  } else {
    let values : Array[Double] = []
    for point in points {
      values.push(
        safe_div(
          2.0 * abs_double(point.predicted - point.actual),
          abs_double(point.predicted) + abs_double(point.actual),
          0.0,
        ),
      )
    }
    robust_mean(values)
  }
}

///|
/// Median absolute forecast error.
pub fn median_absolute_error(points : Array[ForecastPoint]) -> Double {
  let values : Array[Double] = []
  for point in points {
    values.push(abs_double(point.predicted - point.actual))
  }
  median(values)
}

///|
/// Fraction of predictions within an absolute tolerance.
pub fn prediction_coverage(
  points : Array[ForecastPoint],
  tolerance~ : Double,
) -> Double {
  if points.length() == 0 {
    0.0
  } else {
    let mut passed = 0
    for point in points {
      if abs_double(point.predicted - point.actual) <= abs_double(tolerance) {
        passed += 1
      }
    }
    passed.to_double() / points.length().to_double()
  }
}

///|
/// Compute confidence/error bins from results and scored points.
pub fn metric_bins(
  results : Array[EtaResult],
  points : Array[ForecastPoint],
  bin_count? : Int = 5,
) -> Array[MetricBin] {
  let count = if bin_count < 1 { 1 } else { bin_count }
  let bins : Array[MetricBin] = []
  for index in 0..<count {
    let lower = index.to_double() / count.to_double()
    let upper = (index + 1).to_double() / count.to_double()
    let errors : Array[Double] = []
    let confidences : Array[Double] = []
    for result_index, result in results {
      if result.confidence >= lower &&
        (result.confidence < upper || index == count - 1) {
        if result_index < points.length() {
          errors.push(
            abs_double(
              points[result_index].predicted - points[result_index].actual,
            ),
          )
        }
        confidences.push(result.confidence)
      }
    }
    bins.push({
      lower,
      upper,
      count: errors.length(),
      mean_error: robust_mean(errors),
      mean_confidence: robust_mean(confidences),
    })
  }
  bins
}

///|
/// Produce a complete metric report for a result/point pair.
pub fn metric_report(
  results : Array[EtaResult],
  points : Array[ForecastPoint],
  tolerance? : Double = 60.0,
) -> MetricReport {
  {
    summary: summarize_errors(points),
    bias: forecast_bias(points),
    smape: smape(points),
    median_absolute_error: median_absolute_error(points),
    coverage: prediction_coverage(points, tolerance~),
    bins: metric_bins(results, points),
  }
}

///|
/// Return the mean calibration gap across non-empty bins.
pub fn calibration_gap(report : MetricReport) -> Double {
  let gaps : Array[Double] = []
  for bin in report.bins {
    if bin.count > 0 {
      gaps.push(abs_double(bin.mean_error - bin.mean_confidence))
    }
  }
  robust_mean(gaps)
}

///|
/// Return metric values in a stable order for tabular output.
pub fn metric_vector(report : MetricReport) -> Array[Double] {
  [
    report.summary.mae,
    report.summary.rmse,
    report.summary.mape,
    report.bias,
    report.smape,
    report.median_absolute_error,
    report.coverage,
  ]
}

///|
/// Compare two metric reports by a weighted score.
pub fn metric_score(
  report : MetricReport,
  coverage_weight? : Double = 0.2,
) -> Double {
  report.summary.mae +
  report.summary.rmse +
  report.summary.mape * 100.0 -
  abs_double(coverage_weight) * report.coverage
}
