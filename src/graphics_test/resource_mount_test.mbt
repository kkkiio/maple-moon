///|
fn init {
  @res.configure_packs([
    ("base", "assets/base"),
    ("dlc-victoria", "assets/dlc-victoria"),
  ]) catch {
    err => abort("failed to configure graphics resource pack: \{to_repr(err)}")
  }
}
