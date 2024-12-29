test "select char ui" {
  let ui = SelectCharUI::new(
    {
      name_tag: (
        (
          @graphics.Texture::default(),
          @graphics.Texture::default(),
          @graphics.Texture::default(),
        ),
        (
          @graphics.Texture::default(),
          @graphics.Texture::default(),
          @graphics.Texture::default(),
        ),
      ),
      bt_select: { textures: {}, animations: {} },
    },
    [],
  )
  let rs = ui.render()
  @json.inspect!(rs, content={"render_units":[{},{},{},{},{},{},{},{},{}]})
}
