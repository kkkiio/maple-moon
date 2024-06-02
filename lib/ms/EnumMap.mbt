trait IntEnum {
  int_value(Self) -> Int
}

struct EnumMap[K, V] {
  keys : FixedArray[K]
  values : FixedArray[Option[V]]
}

fn EnumMap::make[K, V](enums : FixedArray[K]) -> EnumMap[K, V] {
  { keys: enums, values: FixedArray::make(enums.length(), None) }
}

fn op_get[K : IntEnum, V](self : EnumMap[K, V], k : K) -> Option[V] {
  self.values[k.int_value()]
}

fn op_set[K : IntEnum, V](self : EnumMap[K, V], k : K, v : V) -> Unit {
  self.values[k.int_value()] = Some(v)
}
