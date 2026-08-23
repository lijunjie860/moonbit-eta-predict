///|
fn fold_dataset(
  dataset : ObservationDataset,
  indexes : Array[Int],
) -> ObservationDataset {
  let rows : Array[DatasetRow] = []
  for index in indexes {
    if index >= 0 && index < dataset.rows.length() {
      rows.push(dataset.rows[index])
    }
  }
  { rows, name: "{dataset.name}-fold" }
}

///|
fn complement_indices(length : Int, held_out : Array[Int]) -> Array[Int] {
  let train : Array[Int] = []
  for index in 0..<length {
    if !held_out.contains(index) {
      train.push(index)
    }
  }
  train
}

///|
/// Run deterministic k-fold cross-validation for congestion calibration.
pub fn cross_validate_congestion(
  route : RouteProfile,
  dataset : ObservationDataset,
  fold_count? : Int = 4,
) -> CrossValidationReport {
  let folds = make_folds(dataset.rows.length(), fold_count)
  let reports : Array[CrossValidationFold] = []
  let all_summaries : Array[ErrorSummary] = []
  let candidates : Array[Double] = []
  for fold, test_indexes in folds {
    let train_indexes = complement_indices(dataset.rows.length(), test_indexes)
    let train = fold_dataset(dataset, train_indexes)
    let holdout_rows = fold_dataset(dataset, test_indexes)
    let calibration = grid_calibrate(route, train, steps=8)
    let evaluated = forecast_dataset(
      holdout_rows,
      route,
      congestion=calibration.best.congestion,
    )
    reports.push({
      fold,
      train_count: train.rows.length(),
      test_count: holdout_rows.rows.length(),
      summary: evaluated.summary,
    })
    all_summaries.push(evaluated.summary)
    candidates.push(calibration.best.congestion)
  }
  {
    folds: reports,
    aggregate: combine_error_summaries(all_summaries),
    best_congestion: median(candidates),
  }
}

///|
/// Return the fold with the highest error.
pub fn worst_cross_validation_fold(
  report : CrossValidationReport,
) -> CrossValidationFold? {
  if report.folds.length() == 0 {
    None
  } else {
    let mut worst = report.folds[0]
    for fold in report.folds[1:] {
      if fold.summary.mae > worst.summary.mae {
        worst = fold
      }
    }
    Some(worst)
  }
}

///|
/// Return average fold MAE.
pub fn cross_validation_mean_mae(report : CrossValidationReport) -> Double {
  let values : Array[Double] = []
  for fold in report.folds {
    values.push(fold.summary.mae)
  }
  robust_mean(values)
}

///|
/// Render cross-validation output for CI logs.
pub fn format_cross_validation(report : CrossValidationReport) -> String {
  let builder = StringBuilder()
  builder.write_string(
    "folds=\{report.folds.length()} congestion=\{report.best_congestion}\n",
  )
  for fold in report.folds {
    builder.write_string(
      "fold=\{fold.fold} train=\{fold.train_count} test=\{fold.test_count} mae=\{fold.summary.mae}\n",
    )
  }
  builder.write_string("aggregate ")
  builder.write_string(format_error_summary(report.aggregate))
  builder.to_string()
}

///|
/// Return whether all folds contain both training and test data.
pub fn cross_validation_is_complete(report : CrossValidationReport) -> Bool {
  report.folds.all(fold => fold.train_count > 0 && fold.test_count > 0)
}

///|
/// Evaluate a calibration report on a fixed holdout suffix.
pub fn holdout_evaluate(
  route : RouteProfile,
  dataset : ObservationDataset,
  holdout_ratio? : Double = 0.2,
) -> (GridCalibration, ErrorSummary) {
  let (_, holdout) = split_indices(dataset.rows.length(), holdout_ratio~)
  let train = fold_dataset(
    dataset,
    complement_indices(dataset.rows.length(), holdout),
  )
  let holdout_rows = fold_dataset(dataset, holdout)
  let calibration = grid_calibrate(route, train, steps=10)
  (
    calibration,
    forecast_dataset(
      holdout_rows,
      route,
      congestion=calibration.best.congestion,
    ).summary,
  )
}
