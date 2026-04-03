///|
priv struct DummyResourceLoader {
  dummy : Unit
}

///|
fn DummyResourceLoader::new() -> DummyResourceLoader {
  { dummy: () }
}

///|
impl AsyncResourceLoader for DummyResourceLoader with load_data(self, path) -> Json {
  ignore(self.dummy)
  ignore(path)
  Json::null()
}

///|
fn make_loader() -> AsyncLoader {
  AsyncLoader::new(
    "dummy",
    loader=DummyResourceLoader::new(),
    base_url="/assets",
    image_base_url="/assets",
  )
}

///|
test "async loader resolves json path with base urls" {
  let loader = make_loader()
  inspect(
    loader.resolve_json_path("Npc/Npc/0002007.img/animation.json"),
    content="/assets/Npc/Npc/0002007.img/animation.json",
  )
  inspect(
    loader.resolve_json_path("/assets/Npc/Npc/0002007.img/animation.json"),
    content="/assets/Npc/Npc/0002007.img/animation.json",
  )
  inspect(
    loader.resolve_json_path("https://example.com/a.json"),
    content="https://example.com/a.json",
  )
}

///|
test "missing tag should fail" {
  let loaded : LoadedAnimations = { clips: {}, tags: [] }
  ignore(loaded.clip("not_exists")) catch {
    _ => return
  }
  fail("expected missing tag error")
}
