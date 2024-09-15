// pub fn apply_move(self : Combat, move : @monster.MobSkill, mob : @monster.Mob) -> Unit {
//   if move.is_attack() {
//     let attack = self.prepare_attack(move.is_skill())

//     move.apply_useeffects(mob)
//     move.apply_actions(mob, attack.type)

//     mob.set_afterimage(move.get_id())

//     move.apply_stats(mob, attack)

//     let origin = attack.origin
//     let mut range = attack.range
//     let hrange = (range.left() * attack.hrange) 

//     range =if attack.toleft {
//        @struct.Rectangle::from4( 
//         (origin.x() + hrange) ,
//         (origin.x() + range.right()) ,
//         (origin.y() + range.top()) ,
//         (origin.y() + range.bottom()) ,
//        )
//     } else {
//        @struct.Rectangle::from4( 
//         (origin.x() - range.right()) ,
//         (origin.x() - hrange) ,
//         (origin.y() + range.top()) ,
//         (origin.y() + range.bottom()) ,
//       )
//     }

//     // This approach should also make it easier to implement PvP
//     let mobcount = attack.mobcount
//     let mut result = attack

//     let mob_objs = self.mobs.get_mobs()
//     let reactor_objs = self.reactors.get_reactors()

//     let mob_targets = self.find_closest_mob(mob_objs, range, origin, mobcount, true)
//     let reactor_targets = self.find_closest_reactor(reactor_objs, range, origin, mobcount, false)

//     self.mobs.send_attack(result, attack, mob_targets, mobcount)
//     result.attacker = mob.get_oid()
//     self.extract_effects(mob, move, result)

//     self.apply_use_movement(move)
//     self.apply_result_movement(move, result)

//     self.fn_attack(result)

//     if reactor_targets.is_empty().not() {
//       if let Some(reactor) = reactor_objs.get(reactor_targets[0]) {
//         self.fn_damage_reactor(reactor.get_oid(), mob.get_position(), 0, 0)
//       }
//     }
//   } else {
//     move.apply_useeffects(mob)
//     move.apply_actions(mob, AttackType::MAGIC)

//     let moveid = move.get_id()
//     let level = mob.get_skills().get_level(moveid)
//     self.fn_use_skill(moveid, level)
//   }
// }

// fn find_closest_mob(
//   self : MobCombat,
//   objs : @map_object.MapObjects[@monster.Mob],
//   range : @struct.Rectangle[Int],
//   origin : @struct.Point[Int],
//   objcount : Int,
//   use_mobs : Bool
// ) -> Array[Int] {
//   objs.iter2().iter().flat_map(fn(mob) {
//     if mob.is_alive() && mob.is_in_range(range) {
//       let oid = mob.get_oid()
//       let distance = mob.get_position().distance(origin)
//       Iter::singleton( (distance, oid) )
//     } else {
//       Iter::empty()
//     }
//   }) |> FixedArray::from_iter
//   |> FixedArray::stable_sort
//   .map(fn(pair) { pair.1 })
//   .take(objcount.to_int())
//   .to_array()
// }
