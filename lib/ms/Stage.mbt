// app/src/main/cpp/src/Gameplay/Stage.h
// app/src/main/cpp/src/Gameplay/Stage.cpp

// #pragma once

// #include <chrono>

// #include "../Character/Player.h"
// #include "../IO/KeyType.h"
// #include "Combat/Combat.h"
// #include "Combat/MobCombat.h"
// #include "MapleMap/MapBackgrounds.h"
// #include "MapleMap/MapChars.h"
// #include "MapleMap/MapDrops.h"
// #include "MapleMap/MapEffect.h"
// #include "MapleMap/MapInfo.h"
// #include "MapleMap/MapMobs.h"
// #include "MapleMap/MapNpcs.h"
// #include "MapleMap/MapPortals.h"
// #include "MapleMap/MapReactors.h"
// #include "MapleMap/MapTilesObjs.h"
// #include "Physics/Physics.h"

// namespace ms {
// class Stage : public Singleton<Stage> {
// public:
//     Stage();

//     void init();

//     // Loads the map to display
//     void load(int32_t mapid, int8_t portalid);

//     // Remove all map objects and graphics.
//     void clear();

//     // Remove all channel dependent map objects
//     void clear_channel_objects();

//     // Construct the player from a character entry.
//     void load_player(const CharEntry &entry, uint8_t wid, uint8_t channel_id);

//     // Call 'draw()' of all objects on stage
//     void draw(float alpha) const;

//     // Calls 'update()' of all objects on stage.
//     void update();

//     // Show a character effect
//     void show_character_effect(int32_t cid, CharEffect::Id effect);

//     // Send key input to the stage
//     void send_key(KeyType::Id keytype, int32_t keycode, bool pressed);

//     // Send mouse input to the stage.
//     Cursor::State send_cursor(bool pressed, Point<int16_t> position);

//     void doubleclick(Point<int16_t> pos);

//     // Check if the specified id is the player's id
//     bool is_player(int32_t cid) const;

//     // Returns a reference to the NPCs on the current map.
//     MapNpcs &get_npcs();

//     // Returns a reference to the other characters on the current map.
//     MapChars &get_chars();

//     // Returns a reference to the mobs on the current map.
//     MapMobs &get_mobs();

//     // Returns a reference to the reactors on the current map.
//     MapReactors &get_reactors();

//     // Returns a reference to the drops on the current map.
//     MapDrops &get_drops();

//     // Returns a reference to the Player.
//     Player &get_player();

//     // Return a reference to the attack and buff component.
//     Combat &get_combat();

//     // Return a reference to the mob attack and buff component.
//     MobCombat &get_mob_combat();

//     // Returns the current map ID.
//     int32_t get_mapid();

//     // Return a pointer to a character, possibly the player.
//     std::optional<std::reference_wrapper<Char>> get_character(int32_t cid);

//     // Set a map effect
//     void add_effect(std::string path);

//     // Get the total up time of the client
//     int64_t get_uptime();
//     // Get the level at the start of the client
//     uint16_t get_uplevel();
//     // Get the EXP at the start of the client
//     int64_t get_upexp();

//     // Notify the server that the player has moved maps
//     void transfer_player();

//     void change_channel(uint8_t ch);

// private:
//     void load_map(int32_t mapid);

//     void respawn(int8_t portalid);

//     void check_portals();

//     void check_seats();

//     void check_ladders(bool up);

//     void check_drops();

//     enum State { INACTIVE, TRANSITION, ACTIVE };

//     Camera camera_;
//     Physics physics_;
//     Player player_;

//     std::optional<std::reference_wrapper<Playable>> playable_;
//     State state_;
//     int32_t map_id_;

//     MapInfo map_info_;
//     MapTilesObjs tiles_objs_;
//     MapBackgrounds backgrounds_;
//     MapPortals portals_;
//     MapReactors reactors_;
//     MapNpcs npcs_;
//     MapChars chars_;
//     MapMobs mobs_;
//     MapDrops drops_;
//     MapEffect effect_;

//     Combat combat_;
//     MobCombat mob_combat_;

//     std::chrono::time_point<std::chrono::steady_clock> start_;
//     uint16_t level_before_;
//     int64_t exp_before_;
// };
// }  // namespace ms

// #include "Stage.h"

// #include <nlnx/nx.hpp>
// #include <utility>

// #include "../Configuration.h"
// #include "../IO/UI.h"
// #include "../IO/UITypes/UIStatusBar.h"
// #include "../Net/Packets/AttackAndSkillPackets.h"
// #include "../Net/Packets/GameplayPackets.h"
// #include "../Net/Packets/PlayerInteractionPackets.h"
// #include "../../IO/UITypes/UICharInfo.h"
// #include "../Timer.h"

// namespace ms {
// namespace {
// auto fn_take_damage = []<typename... T>(T && ...args) {
//     TakeDamagePacket(std::forward<T>(args)...).dispatch();
// };
// auto fn_change_map = []<typename... T>(T && ...args) {
//     ChangeMapPacket(std::forward<T>(args)...).dispatch();
// };
// auto fn_pickup_item = []<typename... T>(T && ...args) {
//     PickupItemPacket(std::forward<T>(args)...).dispatch();
// };
// auto fn_player_map_transfer = []<typename... T>(T && ...args) {
//     PlayerMapTransferPacket(std::forward<T>(args)...).dispatch();
// };
// auto fn_admin_enter_map = []<typename... T>(T && ...args) {
//     AdminEnterMapPacket(std::forward<T>(args)...).dispatch();
// };
// auto fn_change_channel = []<typename... T>(T && ...args) {
//     ChangeChannelPacket(std::forward<T>(args)...).dispatch();
// };
// auto fn_char_info_req = []<typename... T>(T && ...args) {
//     CharInfoRequestPacket(std::forward<T>(args)...).dispatch();
// };
// }  // namespace

// Stage::Stage() :
//     state_(State::INACTIVE),
//     map_id_(10000),
//     level_before_(1),
//     combat_(player_, chars_, mobs_, reactors_),
//     mob_combat_(player_, chars_, mobs_),
//     exp_before_(0) {}

// void Stage::init() {
//     drops_.init();
// }

// void Stage::load(int32_t mapid, int8_t portalid) {
//     switch (state_) {
//         case State::INACTIVE:
//             load_map(mapid);
//             respawn(portalid);
//             break;
//         case State::TRANSITION: respawn(portalid); break;
//     }

//     state_ = State::ACTIVE;
// }

// void Stage::load_player(const CharEntry &entry,
//                         uint8_t wid,
//                         uint8_t channel_id) {
//     player_ = Player(entry, wid, channel_id);
//     playable_ = player_;

//     start_ = ContinuousTimer::get().start();

//     CharStats stats = player_.get_stats();
//     level_before_ = stats.get_stat(MapleStat::Id::LEVEL);
//     exp_before_ = stats.get_exp();
// }

// void Stage::clear() {
//     state_ = State::INACTIVE;

//     chars_.clear();
//     npcs_.clear();
//     mobs_.clear();
//     drops_.clear();
//     reactors_.clear();
// }

// void Stage::load_map(int32_t mapid) {
//     Stage::map_id_ = mapid;

//     std::string strid = string_format::extend_id(mapid, 9);
//     std::string prefix = std::to_string(mapid / 100000000);

//     nl::node src = mapid == -1
//                        ? nl::nx::ui["CashShopPreview.img"]
//                        : nl::nx::map["Map"]["Map" + prefix][strid + ".img"];

//     tiles_objs_ = MapTilesObjs(src);
//     backgrounds_ = MapBackgrounds(src["back"]);
//     physics_ = Physics(src["foothold"]);
//     map_info_ = MapInfo(src,
//                         physics_.get_fht().get_walls(),
//                         physics_.get_fht().get_borders());
//     portals_ = MapPortals(src["portal"], mapid);
// }

// void Stage::respawn(int8_t portalid) {
//     Music(map_info_.get_bgm()).play();

//     Point<int16_t> spawnpoint = portals_.get_portal_by_id(portalid);
//     Point<int16_t> startpos = physics_.get_y_below(spawnpoint);
//     player_.respawn(startpos, map_info_.is_underwater());
//     camera_.set_position(startpos);
//     camera_.set_view(map_info_.get_walls(), map_info_.get_borders());
// }

// void Stage::draw(float alpha) const {
//     if (state_ != State::ACTIVE) {
//         return;
//     }

//     Point<int16_t> viewpos = camera_.position(alpha);
//     Point<double> viewrpos = camera_.real_position(alpha);
//     double viewx = viewrpos.x();
//     double viewy = viewrpos.y();

//     backgrounds_.drawbackgrounds(viewx, viewy, alpha);

//     for (auto id : Layer::IDs) {
//         tiles_objs_.draw(id, viewpos, alpha);
//         reactors_.draw(id, viewx, viewy, alpha);
//         npcs_.draw(id, viewx, viewy, alpha);
//         mobs_.draw(id, viewx, viewy, alpha);
//         chars_.draw(id, viewx, viewy, alpha);
//         player_.draw(id, viewx, viewy, alpha);
//         drops_.draw(id, viewx, viewy, alpha);
//     }

//     combat_.draw(viewx, viewy, alpha);
//     mob_combat_.draw(viewx, viewy, alpha);
//     portals_.draw(viewpos, alpha);
//     backgrounds_.drawforegrounds(viewx, viewy, alpha);
//     effect_.draw();
// }

// void Stage::update() {
//     if (state_ != State::ACTIVE) {
//         return;
//     }

//     combat_.update();
//     mob_combat_.update();
//     backgrounds_.update();
//     effect_.update();
//     tiles_objs_.update();

//     reactors_.update(physics_);
//     npcs_.update(physics_);
//     mobs_.update(physics_);
//     chars_.update(physics_);
//     drops_.update(physics_);
//     player_.update(physics_);

//     portals_.update(player_.get_position());
//     camera_.update(player_.get_position());

//     if (player_.is_invincible()) {
//         return;
//     }

//     if (int32_t oid_id = mobs_.find_colliding(player_.get_phobj())) {
//         if (MobAttack attack = mobs_.create_attack(oid_id)) {
//             MobAttackResult result = player_.damage(attack);
//             fn_take_damage(result, TakeDamagePacket::From::TOUCH);
//         }
//     }
// }

// void Stage::show_character_effect(int32_t cid, CharEffect::Id effect) {
//     if (auto character = get_character(cid)) {
//         character->get().show_effect_id(effect);
//     }
// }

// void Stage::check_portals() {
//     if (player_.is_attacking()) {
//         return;
//     }

//     Point<int16_t> playerpos = player_.get_position();
//     Portal::WarpInfo warpinfo = portals_.find_warp_at(playerpos);

//     if (warpinfo.intramap) {
//         Point<int16_t> spawnpoint =
//             portals_.get_portal_by_name(warpinfo.toname);
//         Point<int16_t> startpos = physics_.get_y_below(spawnpoint);

//         player_.respawn(startpos, map_info_.is_underwater());
//     } else if (warpinfo.valid) {
//         fn_change_map(false, -1, warpinfo.name, false);

//         CharStats &stats = Stage::get().get_player().get_stats();

//         stats.set_mapid(warpinfo.mapid);

//         Sound(Sound::Name::PORTAL).play();
//     }
// }

// void Stage::check_seats() {
//     if (player_.is_sitting() || player_.is_attacking()) {
//         return;
//     }

//     auto seat = map_info_.findseat(player_.get_position());
//     player_.set_seat(seat);
// }

// void Stage::check_ladders(bool up) {
//     if (player_.is_climbing() || player_.is_attacking()) {
//         return;
//     }

//     auto ladder = map_info_.findladder(player_.get_position(), up);
//     player_.set_ladder(ladder);
// }

// void Stage::check_drops() {
//     Point<int16_t> playerpos = player_.get_position();
//     auto [drop_oid, drop_pos] = drops_.find_loot_at(playerpos);

//     if (drop_oid) {
//         fn_pickup_item(drop_oid, drop_pos);
//     }
// }

// void Stage::send_key(KeyType::Id type, int32_t action, bool down) {
//     if (state_ != State::ACTIVE || !playable_) {
//         return;
//     }

//     switch (type) {
//         case KeyType::Id::ACTION:
//             if (down) {
//                 switch (action) {
//                     case KeyAction::Id::UP:
//                         check_ladders(true);
//                         check_portals();
//                         break;
//                     case KeyAction::Id::DOWN: check_ladders(false); break;
//                     case KeyAction::Id::SIT: check_seats(); break;
//                     case KeyAction::Id::ATTACK: combat_.use_move(0); break;
//                     case KeyAction::Id::PICKUP: check_drops(); break;
//                 }
//             }

//             playable_->get().send_action(KeyAction::get_action_by_id(action),
//                                          down);
//             break;
//         case KeyType::Id::SKILL: combat_.use_move(action); break;
//         case KeyType::Id::ITEM: player_.use_item(action); break;
//         case KeyType::Id::FACE: player_.set_expression(action); break;
//     }
// }

// Cursor::State Stage::send_cursor(bool pressed, Point<int16_t> position) {
//     auto statusbar = UI::get().get_element<UIStatusBar>();

//     if (statusbar && statusbar->get().is_menu_active()) {
//         if (pressed) {
//             statusbar->get().remove_menus();
//         }

//         if (statusbar->get().is_in_range(position)) {
//             return statusbar->get().send_cursor(pressed, position);
//         }
//     }

//     return npcs_.send_cursor(pressed, position, camera_.position());
// }

// void Stage::doubleclick(Point<int16_t> pos) {
//     auto chr = chars_.get_char(pos, camera_.position());

//     if (chr) {
//         fn_char_info_req(chr->get().get_oid());
//     } else if (chars_.inrange(player_.get_position(),
//                               pos,
//                               camera_.position())) {
//         fn_char_info_req(player_.get_oid());
//     }
// }

// bool Stage::is_player(int32_t cid) const {
//     return cid == player_.get_oid();
// }

// MapNpcs &Stage::get_npcs() {
//     return npcs_;
// }

// MapChars &Stage::get_chars() {
//     return chars_;
// }

// MapMobs &Stage::get_mobs() {
//     return mobs_;
// }

// MapReactors &Stage::get_reactors() {
//     return reactors_;
// }

// MapDrops &Stage::get_drops() {
//     return drops_;
// }

// Player &Stage::get_player() {
//     return player_;
// }

// Combat &Stage::get_combat() {
//     return combat_;
// }

// MobCombat &Stage::get_mob_combat() {
//     return mob_combat_;
// }

// std::optional<std::reference_wrapper<Char>> Stage::get_character(int32_t cid) {
//     if (is_player(cid)) {
//         return create_optional<Char>(&player_);
//     }
//     return create_optional<Char>(chars_.get_char(cid));
// }

// int Stage::get_mapid() {
//     return map_id_;
// }

// void Stage::add_effect(std::string path) {
//     effect_ = MapEffect(std::move(path));
// }

// int64_t Stage::get_uptime() {
//     return ContinuousTimer::get().stop(start_);
// }

// uint16_t Stage::get_uplevel() {
//     return level_before_;
// }

// int64_t Stage::get_upexp() {
//     return exp_before_;
// }

// void Stage::transfer_player() {
//     fn_player_map_transfer();

//     if (Configuration::get().get_admin()) {
//         fn_admin_enter_map(AdminEnterMapPacket::Operation::ALERT_ADMINS);
//     }
// }

// void Stage::clear_channel_objects() {
//     chars_.clear();
//     mobs_.clear();
//     drops_.clear();
//     reactors_.clear();
// }

// void Stage::change_channel(uint8_t ch) {
//     UI::get().disable();
//     GraphicsGL::get().lock();
//     fn_change_channel(ch);
//     player_.set_channel_id(ch);
//     state_ = State::TRANSITION;
// }
// }  // namespace ms

enum StageState {
  INACTIVE
  TRANSITION
  ACTIVE
}

struct Stage {
  state : StageState
}

fn Stage::default() -> Stage {
  { state: StageState::INACTIVE }
}

// Call 'draw()' of all objects on stage
pub fn draw(self : Stage, g : Gl_g, alpha : Double) -> Unit {
  //     if (state_ != State::ACTIVE) {
  //         return;
  //     }

  //     Point<int16_t> viewpos = camera_.position(alpha);
  //     Point<double> viewrpos = camera_.real_position(alpha);
  //     double viewx = viewrpos.x();
  //     double viewy = viewrpos.y();

  //     backgrounds_.drawbackgrounds(viewx, viewy, alpha);

  //     for (auto id : Layer::IDs) {
  //         tiles_objs_.draw(id, viewpos, alpha);
  //         reactors_.draw(id, viewx, viewy, alpha);
  //         npcs_.draw(id, viewx, viewy, alpha);
  //         mobs_.draw(id, viewx, viewy, alpha);
  //         chars_.draw(id, viewx, viewy, alpha);
  //         player_.draw(id, viewx, viewy, alpha);
  //         drops_.draw(id, viewx, viewy, alpha);
  //     }

  //     combat_.draw(viewx, viewy, alpha);
  //     mob_combat_.draw(viewx, viewy, alpha);
  //     portals_.draw(viewpos, alpha);
  //     backgrounds_.drawforegrounds(viewx, viewy, alpha);
  //     effect_.draw();
  // 
}
