///|
let loading_data_ref : Ref[@utils.Future[
  Result[
    (
      @item.ItemData,
      @item.ItemData,
      @item.ItemData,
      @item.ItemData,
      @char_look.Hair,
      @char_look.Face,
    ),
    Error,
  ],
]?] = Ref::new(None)

///|
pub fn get_loading_data() -> @utils.Future[
  Result[
    (
      @item.ItemData,
      @item.ItemData,
      @item.ItemData,
      @item.ItemData,
      @char_look.Hair,
      @char_look.Face,
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
        @item.ItemData,
        @item.ItemData,
        @item.ItemData,
        @item.ItemData,
        @char_look.Hair,
        @char_look.Face,
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
fn get_equipped_slot(slot : Int, invtype : @maple_protocol.InventoryType) -> Int? {
  if invtype == @maple_protocol.InventoryType::EQUIPPED || slot < 0 {
    let real_slot = if slot < 0 { 0 - slot } else { slot }
    Some(real_slot)
  } else {
    None
  }
}

///|
pub fn find_equipped_item_id(
  items : Array[@maple_protocol.InventoryItemEntry],
  slot_id : @slot.Id,
) -> Int? {
  for item in items {
    match item {
      @maple_protocol.InventoryItemEntry::Equip(invtype~, slot~, id~, ..) =>
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
pub fn apply_equipped_stats(
  stats : @char_stats.CharStats,
  items : Array[@maple_protocol.InventoryItemEntry],
) -> Unit {
  stats.init_totalstats()
  for item in items {
    match item {
      @maple_protocol.InventoryItemEntry::Equip(
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
pub fn make_job_from_stats(stats_entry : @maple_protocol.StatsEntry) -> @job.Job {
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
