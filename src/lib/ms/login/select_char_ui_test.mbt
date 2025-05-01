test "select char ui" {
  let ui = SelectCharUI::new(
    SelectCharUIResource::default(),
    [],
    @ui.Hooks::default(),
  )
  let rs = ui.render()
  @json.inspect!(rs, content={"render_units":[{},{},{},{},{},{},{},{}]})
}
