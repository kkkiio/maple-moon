pub(all) type! UnknownEnum Int

pub fn to_string(self : UnknownEnum) -> String {
  "UnknownEnum(\{self})"
}

pub fn flatten_ok[T, E](resutls : Array[Result[T, E]]) -> Result[Array[T], E] {
  let results = Array::new(capacity=resutls.length())
  for result in resutls {
    match result {
      Ok(t) => results.push(t)
      Err(e) => return Err(e)
    }
  }
  Ok(results)
}

pub fn flatten_ok_2[A, B, E](
  res1 : Result[A, E],
  res2 : Result[B, E]
) -> Result[(A, B), E] {
  match (res1, res2) {
    (Ok(a), Ok(b)) => Ok((a, b))
    (Err(e), _) | (_, Err(e)) => Err(e)
  }
}
