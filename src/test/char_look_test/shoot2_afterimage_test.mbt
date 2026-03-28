///|
async test "crossbow shoot2 afterimage without range should render" {
  let previous_world = @ecs.current_world()
  let world = @ecs.World::new()
  @ecs.set_current_world(world)
  defer (match previous_world {
    Some(previous) => @ecs.set_current_world(previous)
    None => @ecs.clear_current_world()
  })
  @capture_app.init_app(
    @app.App::new()
    .with_world(world)
    .with_viewport_width(200.0)
    .with_viewport_height(200.0)
    .add_plugin(@plugins.default_plugin),
  )

  let host = @entity.Entity::new()
  defer host.destroy()
  defer @char_look.clear_after_image(host)
  defer @sprite.sprites().clear()
  @transform2d.set_xy(host, Vec2D(100.0, 100.0))

  let after_image_node = @fs.read_file_to_string(
      "assets/Character/Afterimage/crossBow.img.json",
    )
    |> @json.parse
  let after_images : @char_look.NxAfterImages = @json.from_json(
    after_image_node,
  )
  @char_look.set_after_images("crossBow", after_images)

  let collection = @char_look.AfterImage::get_collection("crossBow", 0)
  guard collection.get("shoot2") is Some(shoot2_resource) else { panic() }

  let current_frame = shoot2_resource.first_frame
  @char_look.add_after_image(
    host,
    fn() { current_frame },
    shoot2_resource,
    true,
  )
  @time.set_delta(0.016)
  @char_look.update_after_image_system(@ecs.require_current_world())
  @capture_app.run_loop(0.016)
  let sprites = @sprite.sprites().iter().collect()
  assert_true(sprites.length() > 0)

  @capture_app.snapshot(
    "src/test/char_look_test/__snapshot__/crossbow_shoot2_afterimage.png",
    img_description="2D game visual effect snapshot.",
  )
}
