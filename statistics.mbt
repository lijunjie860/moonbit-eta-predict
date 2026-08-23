///|
/// Stable sum with a simple compensation term for long traces.
pub fn stable_sum(values : Array[Double]) -> Double {
  let mut total = 0.0
  let mut compensation = 0.0
  for value in values {
    let adjusted = value - compensation
    let next = total + adjusted
    compensation = next - total - adjusted
    total = next
  }
  total
}

///|
/// Arithmetic mean with an explicit empty-input identity.
pub fn robust_mean(values : Array[Double]) -> Double {
  if values.length() == 0 {
    0.0
  } else {
    stable_sum(values) / values.length().to_double()
  }
}

///|
/// Return a sorted copy, keeping the caller's array unchanged.
pub fn sorted_values(values : Array[Double]) -> Array[Double] {
  let sorted = values.copy()
  sorted.sort_by(compare_double)
  sorted
}

///|
/// Median with midpoint interpolation for even-length arrays.
pub fn median(values : Array[Double]) -> Double {
  let sorted = sorted_values(values)
  let length = sorted.length()
  if length == 0 {
    0.0
  } else if length % 2 == 1 {
    sorted[length / 2]
  } else {
    (sorted[length / 2 - 1] + sorted[length / 2]) / 2.0
  }
}

///|
/// Linear-interpolated quantile in the closed probability interval.
pub fn quantile(values : Array[Double], probability~ : Double) -> Double {
  let sorted = sorted_values(values)
  if sorted.length() == 0 {
    0.0
  } else {
    let p = clamp(probability, 0.0, 1.0)
    let position = p * (sorted.length() - 1).to_double()
    let lower = position.to_int()
    let upper = if lower + 1 >= sorted.length() { lower } else { lower + 1 }
    let fraction = position - lower.to_double()
    sorted[lower] + (sorted[upper] - sorted[lower]) * fraction
  }
}

///|
/// Median absolute deviation, a robust scale estimate.
pub fn mad(values : Array[Double]) -> Double {
  let center = median(values)
  let deviations : Array[Double] = []
  for value in values {
    deviations.push(abs_double(value - center))
  }
  median(deviations)
}

///|
/// Population variance for finite or empty sample arrays.
pub fn population_variance(values : Array[Double]) -> Double {
  if values.length() == 0 {
    0.0
  } else {
    let center = robust_mean(values)
    let squares : Array[Double] = []
    for value in values {
      squares.push(square(value - center))
    }
    robust_mean(squares)
  }
}

///|
/// Sample variance, returning zero when degrees of freedom are unavailable.
pub fn sample_variance(values : Array[Double]) -> Double {
  if values.length() <= 1 {
    0.0
  } else {
    let center = robust_mean(values)
    let mut total = 0.0
    for value in values {
      total += square(value - center)
    }
    total / (values.length() - 1).to_double()
  }
}

///|
/// Weighted average that ignores non-positive weights.
pub fn weighted_mean(values : Array[Double], weights : Array[Double]) -> Double {
  let limit = if values.length() < weights.length() {
    values.length()
  } else {
    weights.length()
  }
  let mut numerator = 0.0
  let mut denominator = 0.0
  for index in 0..<limit {
    let weight = if weights[index] < 0.0 { 0.0 } else { weights[index] }
    numerator += values[index] * weight
    denominator += weight
  }
  safe_div(numerator, denominator, 0.0)
}

///|
/// Fraction of values less than or equal to a query value.
pub fn percentile_rank(values : Array[Double], value~ : Double) -> Double {
  if values.length() == 0 {
    0.0
  } else {
    let mut count = 0
    for item in values {
      if item <= value {
        count += 1
      }
    }
    count.to_double() / values.length().to_double()
  }
}

///|
/// Standardized distance from a sample's center.
pub fn z_score(value : Double, values : Array[Double]) -> Double {
  let deviation = population_variance(values).sqrt()
  safe_div(value - robust_mean(values), deviation, 0.0)
}

///|
/// Symmetric confidence interval based on a normal approximation.
pub fn confidence_interval(
  values : Array[Double],
  level? : Double = 0.95,
) -> ConfidenceInterval {
  let estimate = robust_mean(values)
  let deviation = population_variance(values).sqrt()
  let factor = if level >= 0.99 {
    2.576
  } else if level >= 0.95 {
    1.96
  } else {
    1.645
  }
  let margin = if values.length() == 0 {
    0.0
  } else {
    factor * deviation / values.length().to_double().sqrt()
  }
  {
    estimate,
    lower: estimate - margin,
    upper: estimate + margin,
    level: clamp(level, 0.0, 1.0),
  }
}

///|
/// Mean after removing the same proportion from both tails.
pub fn trimmed_mean(
  values : Array[Double],
  proportion? : Double = 0.1,
) -> Double {
  let sorted = sorted_values(values)
  if sorted.length() == 0 {
    0.0
  } else {
    let p = clamp(proportion, 0.0, 0.49)
    let trim = (sorted.length().to_double() * p).to_int()
    let start = trim
    let end = sorted.length() - trim
    if start >= end {
      median(sorted)
    } else {
      let kept : Array[Double] = []
      for index in start..<end {
        kept.push(sorted[index])
      }
      robust_mean(kept)
    }
  }
}

///|
/// Root mean square of a scalar array.
pub fn root_mean_square(values : Array[Double]) -> Double {
  let squares : Array[Double] = []
  for value in values {
    squares.push(square(value))
  }
  robust_mean(squares).sqrt()
}

///|
/// Winsorize both tails while preserving cardinality.
pub fn winsorize(
  values : Array[Double],
  lower_probability? : Double = 0.05,
  upper_probability? : Double = 0.95,
) -> Array[Double] {
  let lower = quantile(values, probability=lower_probability)
  let upper = quantile(values, probability=upper_probability)
  let result : Array[Double] = []
  for value in values {
    result.push(clamp(value, lower, upper))
  }
  result
}

///|
/// Exponentially weighted moving average.
pub fn exponential_mean(
  values : Array[Double],
  alpha? : Double = 0.3,
) -> Double {
  if values.length() == 0 {
    0.0
  } else {
    let weight = clamp(alpha, 0.0001, 1.0)
    let mut current = values[0]
    for value in values[1:] {
      current = weight * value + (1.0 - weight) * current
    }
    current
  }
}

///|
/// Difference between two arrays using the common prefix.
pub fn mean_absolute_difference(
  left : Array[Double],
  right : Array[Double],
) -> Double {
  let limit = if left.length() < right.length() {
    left.length()
  } else {
    right.length()
  }
  if limit == 0 {
    0.0
  } else {
    let differences : Array[Double] = []
    for index in 0..<limit {
      differences.push(abs_double(left[index] - right[index]))
    }
    robust_mean(differences)
  }
}
