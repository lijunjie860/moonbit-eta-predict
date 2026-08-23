///|
/// Summarize a numeric time series.
pub fn summarize_time_series(values : Array[Double]) -> TimeSeriesSummary {
  if values.length() == 0 {
    {
      count: 0,
      first: 0.0,
      last: 0.0,
      minimum: 0.0,
      maximum: 0.0,
      mean: 0.0,
      trend: 0.0,
      volatility: 0.0,
    }
  } else {
    let mut minimum = values[0]
    let mut maximum = values[0]
    for value in values {
      if value < minimum {
        minimum = value
      }
      if value > maximum {
        maximum = value
      }
    }
    let differences = first_differences(values)
    {
      count: values.length(),
      first: values[0],
      last: values[values.length() - 1],
      minimum,
      maximum,
      mean: robust_mean(values),
      trend: if values.length() <= 1 {
        0.0
      } else {
        (values[values.length() - 1] - values[0]) /
        (values.length() - 1).to_double()
      },
      volatility: population_variance(differences).sqrt(),
    }
  }
}

///|
/// Return first differences of a numeric series.
pub fn first_differences(values : Array[Double]) -> Array[Double] {
  let differences : Array[Double] = []
  if values.length() > 1 {
    for index in 1..<values.length() {
      differences.push(values[index] - values[index - 1])
    }
  }
  differences
}

///|
/// Cumulative sum with an explicit starting value.
pub fn cumulative_sum(
  values : Array[Double],
  initial? : Double = 0.0,
) -> Array[Double] {
  let result : Array[Double] = []
  let mut total = initial
  for value in values {
    total += value
    result.push(total)
  }
  result
}

///|
/// Trapezoidal integration over equally spaced samples.
pub fn integrate_series(
  values : Array[Double],
  interval? : Double = 1.0,
) -> Double {
  if values.length() <= 1 {
    0.0
  } else {
    let mut area = 0.0
    for index in 1..<values.length() {
      area += (values[index] + values[index - 1]) * 0.5 * interval
    }
    area
  }
}

///|
/// Linear interpolation at a bounded index coordinate.
pub fn interpolate_series(values : Array[Double], position : Double) -> Double {
  if values.length() == 0 {
    0.0
  } else if values.length() == 1 {
    values[0]
  } else {
    let bounded = clamp(position, 0.0, (values.length() - 1).to_double())
    let lower = bounded.to_int()
    let upper = if lower + 1 >= values.length() { lower } else { lower + 1 }
    let fraction = bounded - lower.to_double()
    values[lower] + (values[upper] - values[lower]) * fraction
  }
}

///|
/// Resample a series to a requested cardinality.
pub fn resample_series(values : Array[Double], count : Int) -> Array[Double] {
  let result : Array[Double] = []
  if count <= 0 {
    result
  } else if count == 1 {
    result.push(interpolate_series(values, 0.0))
    result
  } else {
    for index in 0..<count {
      result.push(
        interpolate_series(
          values,
          index.to_double() *
          (values.length() - 1).to_double() /
          (count - 1).to_double(),
        ),
      )
    }
    result
  }
}

///|
/// Simple trailing moving average with a minimum available prefix.
pub fn moving_average_series(
  values : Array[Double],
  window_size : Int,
) -> Array[Double] {
  let result : Array[Double] = []
  let size = if window_size < 1 { 1 } else { window_size }
  for index in 0..<values.length() {
    let start = if index + 1 > size { index + 1 - size } else { 0 }
    let part : Array[Double] = []
    for position in start..<=index {
      part.push(values[position])
    }
    result.push(robust_mean(part))
  }
  result
}

///|
/// Exponential smoothing with a supplied initial level.
pub fn holt_level(
  values : Array[Double],
  alpha? : Double = 0.3,
  beta? : Double = 0.1,
) -> Array[Double] {
  if values.length() == 0 {
    []
  } else {
    let a = clamp(alpha, 0.0001, 1.0)
    let b = clamp(beta, 0.0, 1.0)
    let result : Array[Double] = [values[0]]
    let mut level = values[0]
    let mut trend = 0.0
    for value in values[1:] {
      let next_level = a * value + (1.0 - a) * (level + trend)
      trend = b * (next_level - level) + (1.0 - b) * trend
      level = next_level
      result.push(level)
    }
    result
  }
}

///|
/// Return indexes where the first difference exceeds a robust threshold.
pub fn change_points(
  values : Array[Double],
  threshold? : Double = 3.0,
) -> Array[Int] {
  let result : Array[Int] = []
  let differences = first_differences(values)
  let center = median(differences)
  let spread = mad(differences)
  for index, difference in differences {
    if abs_double(difference - center) >
      abs_double(threshold) * (spread + 0.000001) {
      result.push(index + 1)
    }
  }
  result
}

///|
/// Forecast a constant-slope horizon from a series.
pub fn extrapolate_series(
  values : Array[Double],
  horizon : Int,
) -> Array[Double] {
  let result : Array[Double] = []
  if horizon <= 0 {
    result
  } else {
    let summary = summarize_time_series(values)
    let mut current = summary.last
    for _ in 0..<horizon {
      current += summary.trend
      result.push(current)
    }
    result
  }
}
