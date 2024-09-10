///https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2019/p0811r3.html
pub fn lerp(a : Double, b : Double, t : Double) -> Double {
  // Exact, monotonic, bounded, determinate, and (for a=b=0) consistent:
  if (a <= 0.0 && b >= 0.0) || (a >= 0.0 && b <= 0.0) {
    return t * b + (1.0 - t) * a
  }
  // exact
  if t == 1.0 {
    return b
  }

  // Exact at t=0, monotonic except near t=1,
  // bounded, determinate, and consistent:
  let x = a + t * (b - a)
  // monotonic near t=1
  return if t > 1.0 == (b > a) {
    @math.maximum(b, x)
  } else {
    @math.minimum(b, x)
  }
}
