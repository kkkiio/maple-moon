///|
async test "crossbow shoot2 afterimage without range should render" {
  @capture_app.init_app(
    @system.App::new()
    .with_canvas_width(200.0)
    .with_canvas_height(200.0)
    .add_plugin(@plugins.default_plugin),
  )

  let host = @entity.Entity::new()
  defer host.destroy()
  defer @char_look.clear_after_image(host)
  defer @sprite.sprites.clear()
  @position.positions.set(host, @position.Position(Vec2D(100.0, 100.0)))

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
  @char_look.update_after_image_system(0.016)
  @capture_app.run_loop(0.016)
  let sprites = @sprite.sprites.iter().collect()
  assert_true(sprites.length() > 0)

  @capture_app.snapshot(
    "src/test/char_look_test/__snapshot__/crossbow_shoot2_afterimage.png",
  )
}
