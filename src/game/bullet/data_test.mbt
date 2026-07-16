///|
fn init {
  @asset.set_io(fn(path) {
    Some(@fs.read_file_to_bytes(path)) catch {
      _ => None
    }
  })
}

///|
test "bullet data load supports official entries without incPAD" {
  try! @res.configure_packs([("base", "assets/base")])
  let arrow = BulletData::load("02060000")
  inspect(
    arrow.watk,
    content=(
      #|0
    ),
  )
  let crossbow_bolt = BulletData::load("02061000")
  inspect(
    crossbow_bolt.watk,
    content=(
      #|0
    ),
  )
  @res.clear_mounts()
}
