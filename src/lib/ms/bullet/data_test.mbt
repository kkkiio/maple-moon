///|
async test "bullet data load supports official entries without incPAD" {
  @local_loader.install_resource_env_for_test()
  let arrow = BulletData::load("02060000")
  inspect(arrow.watk, content="0")
  let crossbow_bolt = BulletData::load("02061000")
  inspect(crossbow_bolt.watk, content="0")
}
