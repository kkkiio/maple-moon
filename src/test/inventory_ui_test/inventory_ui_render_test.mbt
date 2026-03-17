///|
using @server_proto {
  type InventoryEntry,
  type InventoryItemEntry,
  type InventoryType,
}

///|
fn make_inventory_entry() -> InventoryEntry {
  let slot_maxs : @resource.EnumMap[InventoryType, Int] = @resource.EnumMap::default()
  slot_maxs.0.set(InventoryType::EQUIP, 24)
  slot_maxs.0.set(InventoryType::USE, 24)
  slot_maxs.0.set(InventoryType::SETUP, 24)
  slot_maxs.0.set(InventoryType::ETC, 24)
  let items : Array[InventoryItemEntry] = [
    InventoryItemEntry::Item(
      invtype=InventoryType::EQUIP,
      slot=1,
      id=1060002,
      cash=false,
      expire=0,
      count=25,
      owner="",
      flag=0,
    ),
    InventoryItemEntry::Item(
      invtype=InventoryType::USE,
      slot=1,
      id=2000000,
      cash=false,
      expire=0,
      count=25,
      owner="",
      flag=0,
    ),
  ]
  { meso: 654321, slot_maxs, items }
}

///|
async fn setup_inventory_ui_test_scene() -> Unit {
  let app = @app.App::new()
    .with_viewport_width(800.0)
    .with_viewport_height(540.0)
    .add_plugin(@plugins.default_plugin)
    .add_system(
      Update,
      fn(_world) { @inventory_ui.inventory_ui_system(@time.delta()) },
      system_name="inventory_ui_system",
    )
    .add_system(
      Update,
      fn(_world) { @io_service.io_system(@time.delta()) },
      system_name="io_system",
    )
  @capture_app.init_app(app)

  let character_loader = @local_loader.make_local_character_loader()
  let item_loader = @local_loader.make_local_item_loader()
  @resource.set_character_loader(character_loader)
  @resource.set_item_loader(item_loader)
  @resource.set_string_loader(@local_loader.make_local_string_loader())
  let equip_data = @item.ItemData::load(1060002, character_loader, item_loader)
  let use_data = @item.ItemData::load(2000000, character_loader, item_loader)
  @item.ItemData::add_item_data(1060002, equip_data)
  @item.ItemData::add_item_data(2000000, use_data)

  let ui_item_json = @fs.read_file_to_string(
      "assets/ui/UIWindow2.img/Item.json",
    )
    |> @json.parse
  @inventory_ui.set_panel_position_for_test(16, 16)
  @inventory_ui.set_item_json_for_test(ui_item_json)
  @inventory_ui.set_inventory_entry(make_inventory_entry())
  @inventory_ui.set_inventory_visible(true)

  for _ in 0..<60 {
    @capture_app.run_loop(0.016)
  }
}

///|
async test "inventory ui renders equip tab with icon count and meso" {
  defer @inventory_ui.set_inventory_visible(false)
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites().clear()
  setup_inventory_ui_test_scene()
  @capture_app.snapshot(
    "src/test/inventory_ui_test/__snapshot__/inventory_ui_default.png",
  )
}

///|
async test "inventory ui renders use tab with icon count and meso" {
  defer @inventory_ui.set_inventory_visible(false)
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites().clear()
  setup_inventory_ui_test_scene()
  @inventory_ui.set_tab_index_for_test(1)
  for _ in 0..<2 {
    @capture_app.run_loop(0.016)
  }
  @capture_app.snapshot(
    "src/test/inventory_ui_test/__snapshot__/inventory_ui_use_tab.png",
  )
}
