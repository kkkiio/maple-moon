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
fn setup_inventory_ui_test_scene() -> @app.App raise {
  let app = @app.App()
    .with_viewport_width(800.0)
    .with_viewport_height(540.0)
    .add_plugin(@plugins.default_plugin)
    .add_system(
      Update,
      fn(world) { @inventory_ui.inventory_ui_system(world) },
      system_name="inventory_ui_system",
    )
    .add_system(
      Update,
      fn(world) { @io_service.io_system(world) },
      system_name="io_system",
    )
  @ecs.set_current_world(app.world())
  @system.configure_display(800.0, 540.0, 1.0)

  let equip_data = @item.ItemData::load(1060002)
  let use_data = @item.ItemData::load(2000000)
  @item.ItemData::add_item_data(1060002, equip_data)
  @item.ItemData::add_item_data(2000000, use_data)

  let ui_item_json = @fs.read_file_to_string(
      "assets/UI/UIWindow2.img/Item.json",
    )
    |> @json.parse
  @inventory_ui.set_panel_position_for_test(16, 16)
  @inventory_ui.set_item_json_for_test(ui_item_json)
  @inventory_ui.set_inventory_entry(make_inventory_entry())
  @inventory_ui.set_inventory_visible(true)
  app
}

///|
test "inventory ui renders equip tab with icon count and meso" {
  defer @inventory_ui.set_inventory_visible(false)
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites().clear()
  let app = setup_inventory_ui_test_scene()
  @capture_app.ensure_webgpu_capture_runtime(800.0, 540.0)
  let captures = app.run_frames_capture(60, raw_delta=0.016)
  @capture_app.snapshot(
    "src/tests/inventory_ui_test/__snapshot__/inventory_ui_default.png",
    captures[captures.length() - 1].png,
    visual_desc="Inventory UI is displayed showing the default equip tab with items.",
  )
}

///|
test "inventory ui renders use tab with icon count and meso" {
  defer @inventory_ui.set_inventory_visible(false)
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites().clear()
  let app = setup_inventory_ui_test_scene()
  @inventory_ui.set_tab_index_for_test(1)
  @capture_app.ensure_webgpu_capture_runtime(800.0, 540.0)
  let captures = app.run_frames_capture(62, raw_delta=0.016)
  @capture_app.snapshot(
    "src/tests/inventory_ui_test/__snapshot__/inventory_ui_use_tab.png",
    captures[captures.length() - 1].png,
    visual_desc="Inventory UI is displayed showing the use tab with items.",
  )
}
