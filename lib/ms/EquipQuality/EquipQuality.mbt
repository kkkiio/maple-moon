// app/src/main/cpp/src/Character/Inventory/EquipQuality.h
// app/src/main/cpp/src/Character/Inventory/EquipQuality.cpp
pub enum Id {
  GREY
  WHITE
  ORANGE
  BLUE
  VIOLET
  GOLD
} derive(Eq)

// pub fn check_quality(
//   item_id : Int,
//   scrolled : Bool,
//   stats : @immut/hashmap.T[@EquipStat.Id, Int]
// ) -> Id {
//   let data = @ms.EquipData::get(item_id)
//   let mut delta : Int = 0
//   stats.each(
//     fn(es, stat) {
//       let defstat = data.get_defstat(es)
//       delta += stat - defstat
//     },
//   )
//   if delta < -5 {
//     if scrolled {
//       return Id::ORANGE
//     } else {
//       return Id::GREY
//     }
//   }
//   if delta < 7 {
//     if scrolled {
//       return Id::ORANGE
//     } else {
//       return Id::WHITE
//     }
//   }
//   if delta < 14 {
//     return Id::BLUE
//   }
//   if delta < 21 {
//     return Id::VIOLET
//   }
//   return Id::GOLD
// }
