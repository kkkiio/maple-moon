///|
fn init {
  @res.configure_packs([("base", "assets/base")]) catch {
    err => abort("failed to configure graphics resource pack: \{to_repr(err)}")
  }
}
