///|
/// A deterministic linear-congruential state for reproducible fixtures.
pub(all) struct Sampler {
  state : UInt64
} derive(Debug, Eq)

///|
/// Create a sampler, replacing a zero seed with a stable non-zero seed.
pub fn Sampler::new(seed : UInt64) -> Sampler {
  { state: if seed == 0 { 88172645463325252 } else { seed } }
}

///|
/// Return the next pseudo-random 64-bit value.
pub fn Sampler::next(self : Sampler) -> (Sampler, UInt64) {
  let next = self.state * 6364136223846793005 + 1442695040888963407
  ({ state: next }, next)
}

///|
/// Return a deterministic unit interval sample.
pub fn Sampler::unit(self : Sampler) -> (Sampler, Double) {
  let (next, value) = self.next()
  (next, (value % 1000000).to_double() / 1000000.0)
}

///|
/// Return a deterministic signed perturbation.
pub fn Sampler::noise(self : Sampler, magnitude~ : Double) -> (Sampler, Double) {
  let (next, unit) = self.unit()
  (next, (unit * 2.0 - 1.0) * magnitude)
}

///|
/// Generate evenly spaced indexes for a deterministic sample.
pub fn sample_indices(length : Int, count : Int) -> Array[Int] {
  let result : Array[Int] = []
  if length <= 0 || count <= 0 {
    result
  } else {
    let actual = if count > length { length } else { count }
    for index in 0..<actual {
      result.push(index * length / actual)
    }
    result
  }
}

///|
/// Split an array into an ordered train and holdout prefix/suffix.
pub fn split_indices(
  length : Int,
  holdout_ratio? : Double = 0.2,
) -> (Array[Int], Array[Int]) {
  let ratio = clamp(holdout_ratio, 0.0, 0.9)
  let holdout = (length.to_double() * ratio).to_int()
  let split = if holdout > length { 0 } else { length - holdout }
  let train : Array[Int] = []
  let holdout_indices : Array[Int] = []
  for index in 0..<length {
    if index < split {
      train.push(index)
    } else {
      holdout_indices.push(index)
    }
  }
  (train, holdout_indices)
}

///|
/// Copy values at valid indexes, ignoring indexes outside the source.
pub fn select_values(
  values : Array[Double],
  indices : Array[Int],
) -> Array[Double] {
  let result : Array[Double] = []
  for index in indices {
    if index >= 0 && index < values.length() {
      result.push(values[index])
    }
  }
  result
}

///|
/// Create fixed-size contiguous folds for cross-validation.
pub fn make_folds(length : Int, fold_count : Int) -> Array[Array[Int]] {
  let result : Array[Array[Int]] = []
  if length <= 0 || fold_count <= 0 {
    result
  } else {
    let folds = if fold_count > length { length } else { fold_count }
    for fold in 0..<folds {
      let indexes : Array[Int] = []
      for index in 0..<length {
        if index % folds == fold {
          indexes.push(index)
        }
      }
      result.push(indexes)
    }
    result
  }
}

///|
/// Resample values cyclically to a requested size; useful for deterministic fixtures.
pub fn repeat_to(values : Array[Double], size : Int) -> Array[Double] {
  let result : Array[Double] = []
  if values.length() == 0 || size <= 0 {
    result
  } else {
    for index in 0..<size {
      result.push(values[index % values.length()])
    }
    result
  }
}

///|
/// Produce a sequence of monotonic timestamps.
pub fn timestamp_grid(
  start : Double,
  interval : Double,
  count : Int,
) -> Array[Double] {
  let result : Array[Double] = []
  let safe_interval = if interval < 0.0 { 0.0 } else { interval }
  for index in 0..<count {
    result.push(start + safe_interval * index.to_double())
  }
  result
}

///|
/// Add bounded deterministic noise to a numeric trace.
pub fn noisy_values(
  values : Array[Double],
  seed : UInt64,
  magnitude~ : Double,
) -> Array[Double] {
  let result : Array[Double] = []
  let mut sampler = Sampler::new(seed)
  for value in values {
    let (next, noise) = sampler.noise(magnitude~)
    sampler = next
    result.push(value + noise)
  }
  result
}

///|
/// Return an array of unit weights of a requested length.
pub fn unit_weights(length : Int) -> Array[Double] {
  let result : Array[Double] = []
  for _ in 0..<length {
    result.push(1.0)
  }
  result
}
