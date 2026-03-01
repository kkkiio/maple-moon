///|
let loading_data_ref : Ref[
  @utils.Future[
    Result[
      (
        @item.ItemData?,
        @item.ItemData?,
        @item.ItemData?,
        @item.ItemData?,
        @char_look.Hair,
        @char_look.Face,
        @resource.AsyncLoader,
        @resource.AsyncLoader,
      ),
      Error,
    ],
  ]?,
] = Ref::new(None)

///|
pub fn get_loading_data() -> @utils.Future[
  Result[
    (
      @item.ItemData?,
      @item.ItemData?,
      @item.ItemData?,
      @item.ItemData?,
      @char_look.Hair,
      @char_look.Face,
      @resource.AsyncLoader,
      @resource.AsyncLoader,
    ),
    Error,
  ],
]? {
  loading_data_ref.val
}

///|
pub fn set_loading_data(
  fut : @utils.Future[
    Result[
      (
        @item.ItemData?,
        @item.ItemData?,
        @item.ItemData?,
        @item.ItemData?,
        @char_look.Hair,
        @char_look.Face,
        @resource.AsyncLoader,
        @resource.AsyncLoader,
      ),
      Error,
    ],
  ],
) -> Unit {
  loading_data_ref.val = Some(fut)
}

///|
pub fn clear_loading_data() -> Unit {
  loading_data_ref.val = None
}

///|
let active_scene_map_ref : Ref[@map.SceneMap?] = Ref::new(None)

///|
/// Store the active map runtime objects after map loading finished.
pub fn set_active_scene_map(scene_map : @map.SceneMap) -> Unit {
  active_scene_map_ref.val = Some(scene_map)
}

///|
/// Get the active map runtime objects for in-scene systems.
pub fn get_active_scene_map() -> @map.SceneMap? {
  active_scene_map_ref.val
}

///|
/// Clear active map runtime objects when leaving current scene.
pub fn clear_active_scene_map() -> Unit {
  active_scene_map_ref.val = None
}

///|
fn get_equipped_slot(slot : Int, invtype : @server_proto.InventoryType) -> Int? {
  if invtype == @server_proto.InventoryType::EQUIPPED || slot < 0 {
    let real_slot = if slot < 0 { 0 - slot } else { slot }
    Some(real_slot)
  } else {
    None
  }
}

///|
pub fn find_equipped_item_id(
  items : Array[@server_proto.InventoryItemEntry],
  slot_id : @slot.Id,
) -> Int? {
  for item in items {
    match item {
      @server_proto.InventoryItemEntry::Equip(invtype~, slot~, id~, ..) =>
        match get_equipped_slot(slot, invtype) {
          Some(real_slot) =>
            if real_slot == slot_id.int_value() {
              return Some(id)
            }
          None => ()
        }
      _ => ()
    }
  }
  None
}

///|
/// Collect all item ids carried by `SetField` inventory snapshot.
pub fn collect_inventory_item_ids(
  items : Array[@server_proto.InventoryItemEntry],
) -> Array[Int] {
  let id_set : Map[Int, Bool] = Map::new()
  for item in items {
    let item_id = match item {
      @server_proto.InventoryItemEntry::Equip(id~, ..) => id
      @server_proto.InventoryItemEntry::Item(id~, ..) => id
      @server_proto.InventoryItemEntry::Pet(id~, ..) => id
    }
    if item_id > 0 {
      id_set.set(item_id, true)
    }
  }
  let ids : Array[Int] = []
  for item_id, _ in id_set {
    ids.push(item_id)
  }
  ids
}

///|
pub fn apply_equipped_stats(
  stats : @char_stats.CharStats,
  items : Array[@server_proto.InventoryItemEntry],
) -> Unit {
  stats.init_totalstats()
  for item in items {
    match item {
      @server_proto.InventoryItemEntry::Equip(
        invtype~,
        slot~,
        stats=equip_stats,
        ..
      ) =>
        if get_equipped_slot(slot, invtype) is Some(_) {
          for stat_id, value in equip_stats.0 {
            stats.add_value(stat_id, value)
          }
        }
      _ => ()
    }
  }
  stats.close_totalstats()
}

///|
pub fn make_job_from_stats(stats_entry : @server_proto.StatsEntry) -> @job.Job {
  let job_id = stats_entry.stats.0.get(@maple_stat.Id::JOB).unwrap_or(0)
  let level = if job_id == 0 {
    @job.Level::BEGINNER
  } else if job_id % 100 == 0 {
    @job.Level::FIRST
  } else if job_id % 10 == 0 {
    @job.Level::SECOND
  } else if job_id % 10 == 1 {
    @job.Level::THIRD
  } else {
    @job.Level::FOURTH
  }
  @job.Job::new(job_id, level, Map::new())
}
