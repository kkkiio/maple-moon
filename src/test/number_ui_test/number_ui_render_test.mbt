///|
fn sprite_count() -> Int {
  let mut count = 0
  for _, _ in @sprite.sprites() {
    count += 1
  }
  count
}

///|
fn entity_count() -> Int {
  @entity.iter_entities().to_array().length()
}

///|
async fn setup_number_scene() -> Unit {
  @resource.register_async_loader(
    "effect",
    @resource.AsyncLoader::new(
      "test_local_effect",
      loader=@resource.CompositeAsyncResourceLoader::new({
        "BasicEff.img/": @local_loader.LocalDirResourceLoader::new(
          "assets/Effect/BasicEff.img",
        ),
        "CharacterEff.img/": @local_loader.LocalDirResourceLoader::new(
          "assets/Effect/CharacterEff.img",
        ),
      }),
    ),
  )

  let app = @app.App::new()
    .with_viewport_width(320.0)
    .with_viewport_height(240.0)
    .add_plugin(@plugins.default_plugin)
    .add_system(
      Update,
      fn(world) { @ui.ui_system(world) },
      system_name="ui_system",
    )
    .add_system(
      Update,
      fn(world) { @ui.number_system(world) },
      system_name="number_system",
    )
    .add_system(
      Update,
      fn(world) { @io_service.io_system(world) },
      system_name="io_system",
    )
  @capture_app.init_app(app)

  for _ in 0..<30 {
    @capture_app.run_loop(0.016)
    @async.sleep(0)
  }
}

///|
async test "number ui moves up and fades out with frame delta update" {
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites().clear()

  setup_number_scene()
  let baseline_sprites = sprite_count()
  let baseline_entities = entity_count()
  @ui.show_number(@ui.NumberType::HURT, 12345, 140, x=160)

  @capture_app.run_loop(0.016)
  @async.sleep(0)
  assert_true(sprite_count() > baseline_sprites)
  assert_true(entity_count() > baseline_entities)

  for _ in 0..<12 {
    @capture_app.run_loop(0.016)
    @async.sleep(0)
  }
  assert_true(sprite_count() > baseline_sprites)

  for _ in 0..<60 {
    @capture_app.run_loop(0.016)
    @async.sleep(0)
  }
  assert_true(entity_count() == baseline_entities)
}
