///|
using @server_proto {
  type InventoryEntry,
  type InventoryItemEntry,
  type InventoryType,
  type OpenNpcShopMessage,
}

///|
fn make_inventory_entry() -> InventoryEntry {
  let slot_maxs : @resource.EnumMap[InventoryType, Int] = @resource.EnumMap::default()
  slot_maxs.0.set(InventoryType::EQUIP, 24)
  slot_maxs.0.set(InventoryType::USE, 24)
  slot_maxs.0.set(InventoryType::SETUP, 24)
  slot_maxs.0.set(InventoryType::ETC, 24)
  slot_maxs.0.set(InventoryType::CASH, 24)
  let items : Array[InventoryItemEntry] = [
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
    InventoryItemEntry::Item(
      invtype=InventoryType::ETC,
      slot=1,
      id=4000000,
      cash=false,
      expire=0,
      count=7,
      owner="",
      flag=0,
    ),
  ]
  { meso: 765432, slot_maxs, items }
}

///|
fn load_shop2_json_for_test() -> Json raise {
  let shop2_raw = @json.parse(
    @fs.read_file_to_string("assets/ui/UIWindow2.img/Shop2.json"),
  )
  let spritesheet_names = [
    "BtBuy", "BtExit", "BtRecharge", "BtSell", "MesoWorthCoin", "TabBuy", "TabSell",
    "TabShop", "checkBox",
  ]
  let spritesheet_jsons : Map[String, @resource.SpritesheetMetadata] = Map::new()
  for name in spritesheet_names {
    let meta_json = @json.parse(
      @fs.read_file_to_string(
        "assets/spritesheets/UI/UIWindow2.img/Shop2/\{name}.json",
      ),
    )
    let meta : @resource.SpritesheetMetadata = @json.from_json(meta_json)
    spritesheet_jsons.set("spritesheets/UI/UIWindow2.img/Shop2/\{name}", meta)
  }
  @resource.patch_image(shop2_raw, spritesheet_jsons, base_url="/assets")
}

///|
async fn load_open_shop_message_for_map_102000001() -> OpenNpcShopMessage {
  // 102000001 has npc ids 1021000 and 1021001.
  let map_npc_ids = [1021000, 1021001]
  let by_npc_id = @shop_sheet.load_npc_shop_map(@resource.get_csv_loader())
  for npc_id in map_npc_ids {
    if by_npc_id.get(npc_id) is Some(shop) {
      return shop
    }
  }
  panic()
}

///|
async fn preload_shop_items_for_snapshot(
  shop : OpenNpcShopMessage,
  character_loader : @resource.AsyncLoader,
  item_loader : @resource.AsyncLoader,
) -> Unit {
  let loaded_ids : Map[Int, Bool] = {}
  for item in shop.items {
    if loaded_ids.contains(item.id) {
      continue
    }
    let data = @item.ItemData::load(item.id, character_loader, item_loader)
    @item.ItemData::add_item_data(item.id, data)
    loaded_ids.set(item.id, true)
  }
  // Preload test inventory item data to keep sell-tab snapshot deterministic.
  let etc_item_data = @item.ItemData::load(
    4000000, character_loader, item_loader,
  )
  @item.ItemData::add_item_data(4000000, etc_item_data)
}

///|
async fn setup_shop_ui_scene() -> Unit {
  @capture_app.init_app(
    @system.App::new()
    .with_viewport_width(820.0)
    .with_viewport_height(620.0)
    .add_plugin(@plugins.default_plugin)
    .add_system(@shop_ui.shop_ui_system, system_name="shop_ui_system")
    .add_system(@io_service.io_system, system_name="io_system"),
  )

  @local_loader.install_local_csv_loader()
  let character_loader = @local_loader.make_local_character_loader()
  let item_loader = @local_loader.make_local_item_loader()
  let shop = load_open_shop_message_for_map_102000001()
  @resource.set_character_loader(character_loader)
  @resource.set_item_loader(item_loader)
  @resource.set_string_loader(@local_loader.make_local_string_loader())
  preload_shop_items_for_snapshot(shop, character_loader, item_loader)
  let shop2_json = load_shop2_json_for_test()

  @shop_ui.set_shop2_json_for_test(shop2_json)
  @shop_ui.set_panel_position_for_test(20, 20)
  @shop_ui.set_inventory_entry_for_test(make_inventory_entry())
  @shop_ui.set_open_shop_for_test(Some(shop))

  for _ in 0..<20 {
    @capture_app.run_loop(0.016)
  }
}

///|
async test "shop ui renders perion style panel (map 102000001)" {
  defer @shop_ui.set_shop_visible_for_test(false)
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites.clear()
  setup_shop_ui_scene()
  @capture_app.snapshot(
    "src/test/shop_ui_test/__snapshot__/shop_ui_map_102000001.png",
  )
}

///|
async test "shop ui renders etc sell tab (map 102000001)" {
  defer @shop_ui.set_shop_visible_for_test(false)
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites.clear()
  setup_shop_ui_scene()
  @shop_ui.set_sell_tab_index_for_test(2)
  for _ in 0..<2 {
    @capture_app.run_loop(0.016)
  }
  @capture_app.snapshot(
    "src/test/shop_ui_test/__snapshot__/shop_ui_map_102000001_etc_tab.png",
  )
}
