///|
pub fn ints(start~ : Int = 0) -> Iter[Int] {
  start.until(@int.max_value)
}
