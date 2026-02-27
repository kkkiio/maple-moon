///|
using @server_proto {
  type InventoryEntry,
  type InventoryItemEntry,
  type InventoryType,
  type OpenNpcShopMessage,
  type ShopItem,
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
      id=1060002,
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
fn make_open_shop_message() -> OpenNpcShopMessage {
  let items : Array[ShopItem] = [
    {
      id: 2000000,
      price: 50,
      pitch: 0,
      time: 0,
      charge_price: 0,
      buyable: 1000,
    },
    {
      id: 1060002,
      price: 300,
      pitch: 0,
      time: 0,
      charge_price: 0,
      buyable: 1000,
    },
    {
      id: 2000000,
      price: 75,
      pitch: 0,
      time: 0,
      charge_price: 0,
      buyable: 1000,
    },
  ]
  { npc_id: 1022100, items }
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
async fn setup_shop_ui_scene() -> Unit {
  @capture_app.init_app(
    @system.App::new()
    .with_canvas_width(820.0)
    .with_canvas_height(620.0)
    .add_plugin(@plugins.default_plugin)
    .add_system(@shop_ui.shop_ui_system, system_name="shop_ui_system")
    .add_system(@io_service.io_system, system_name="io_system"),
  )

  let character_loader = @local_loader.make_local_character_loader()
  let item_loader = @local_loader.make_local_item_loader()
  let blue_jean = @item.ItemData::load(1060002, character_loader, item_loader)
  let red_potion = @item.ItemData::load(2000000, character_loader, item_loader)
  @item.ItemData::add_item_data(1060002, blue_jean)
  @item.ItemData::add_item_data(2000000, red_potion)
  let shop2_json = load_shop2_json_for_test()

  @shop_ui.set_shop2_json_for_test(shop2_json)
  @shop_ui.set_panel_position_for_test(20, 20)
  @shop_ui.set_inventory_entry_for_test(make_inventory_entry())
  @shop_ui.set_open_shop_for_test(Some(make_open_shop_message()))

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
