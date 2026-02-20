///|
using @maple_protocol { type InventoryEntry, type InventoryType }

///|
fn make_inventory_entry() -> InventoryEntry {
  let slot_maxs : @resource.EnumMap[InventoryType, Int] = @resource.EnumMap::default()
  slot_maxs.0.set(InventoryType::EQUIP, 24)
  slot_maxs.0.set(InventoryType::USE, 24)
  slot_maxs.0.set(InventoryType::SETUP, 24)
  slot_maxs.0.set(InventoryType::ETC, 24)
  {
    meso: 123456,
    slot_maxs,
    items: [],
  }
}

///|
async test "inventory ui render snapshot" {
  defer @inventory_ui.set_inventory_visible(false)
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites.clear()

  @capture_app.init_app(
    @system.App::new()
    .with_canvas_width(800.0)
    .with_canvas_height(540.0)
    .add_plugin(@plugins.default_plugin)
    .add_system(@inventory_ui.inventory_ui_system, system_name="inventory_ui_system")
    .add_system(@io_service.io_system, system_name="io_system"),
  )

  let ui_item_json = @fs.read_file_to_string("assets/ui/UIWindow2.img/Item.json")
    |> @json.parse
  @inventory_ui.set_panel_position_for_test(16, 16)
  @inventory_ui.set_item_json_for_test(ui_item_json)
  @inventory_ui.set_inventory_entry(make_inventory_entry())
  @inventory_ui.set_inventory_visible(true)

  for _ in 0..<2 {
    @capture_app.run_loop(0.016)
  }

  @capture_app.snapshot(
    "src/test/inventory_ui_test/__snapshot__/inventory_ui_default.png",
  )
}
