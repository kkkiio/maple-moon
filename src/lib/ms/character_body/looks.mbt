///|
pub(all) struct NxStanceLooks[T](Map[StanceId, Array[T]])

///|
pub impl[T : @json.FromJson] @json.FromJson for NxStanceLooks[T] with from_json(
  json,
  path,
) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "expect object"))
  }
  let map = Map([])
  for k, v in obj {
    guard StanceId::from_name(k) is Some(stance_id) else { continue }
    let nodes : Array[T] = @resource.parse_map_based_array(
      v,
      path=path.add_key(k),
    )
    map.set(stance_id, nodes)
  }
  map
}
