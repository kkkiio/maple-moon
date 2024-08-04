pub fn new_login_start_packet() -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::LOGIN_START)
}

pub fn new_login_packet(acc : String, pass : String) -> @net.OutPacket {
  let packet = @net.OutPacket::new(@net.OutPacketOpcode::LOGIN)
  let volume_serial_number = @config.global().get_volume_serial_number()
  let part1 = volume_serial_number.substring(start=0, end=2)
  let part2 = volume_serial_number.substring(start=2, end=4)
  let part3 = volume_serial_number.substring(start=4, end=6)
  let part4 = volume_serial_number.substring(start=6, end=8)
  let h = @net.hex_to_dec?(part4).unwrap()
  let w = @net.hex_to_dec?(part3).unwrap()
  let i = @net.hex_to_dec?(part2).unwrap()
  let d = @net.hex_to_dec?(part1).unwrap()
  packet..write_string(acc)..write_string(pass)..skip(6)..write_byte(h)..write_byte(
    w,
  )..write_byte(i)..write_byte(d)
}

/// Handler for a packet that contains the response to an attempt at logging in
struct LoginResultHandler {} derive(Default)

fn LoginResultHandler::new() -> LoginResultHandler {
  LoginResultHandler::default()
}

fn handle(self : LoginResultHandler, recv : @net.InPacket) -> Unit!Error {
  // auto loginwait = UI::get().get_element<UILoginWait>();

  // if (loginwait && loginwait->get().is_active()) {
  //     std::function<void()> okhandler = loginwait->get().get_handler();

  //     // Remove previous UIs
  //     UI::get().remove(UIElement::Type::LOGIN_NOTICE);
  //     UI::get().remove(UIElement::Type::LOGIN_WAIT);
  //     UI::get().remove(UIElement::Type::TOS);
  //     UI::get().remove(UIElement::Type::GENDER);

  // The packet should contain a 'reason' integer which can signify
  // various things
  match recv.read_int!() {
    // Login successful
    // The packet contains information on the account, so we initialize
    // the account with it.
    0 => {
      let account = parse_account!(recv)
      @config.global().set_admin(account.admin)
      // Save the "Login ID" if the box for it on the login screen is
      // checked
      //             if (Setting<SaveLogin>::get().load()) {
      //                 Setting<DefaultAccount>::get().save(account.name);
      //             }

      // AfterLoginPacket("1111").dispatch();

      // Request the list of worlds and channels online.
      fn_server_req()
    }
    //         // Login unsuccessful
    //         // The LoginNotice displayed will contain the specific information
    //         switch (reason) {
    //             case 2:
    //                 UI::get().emplace<UILoginNotice>(
    //                     UILoginNotice::Message::BLOCKED_ID,
    //                     okhandler);
    //                 break;
    //             case 5:
    //                 UI::get().emplace<UILoginNotice>(
    //                     UILoginNotice::Message::NOT_REGISTERED,
    //                     okhandler);
    //                 break;
    //             case 7:
    //                 UI::get().emplace<UILoginNotice>(
    //                     UILoginNotice::Message::ALREADY_LOGGED_IN,
    //                     okhandler);
    //                 break;
    //             case 13:
    //                 UI::get().emplace<UILoginNotice>(
    //                     UILoginNotice::Message::UNABLE_TO_LOGIN_WITH_IP,
    //                     okhandler);
    //                 break;
    23 =>
      // UI::get().emplace<UITermsOfService>(okhandler); break;
      fn_tos()
    //             default:
    //                 // Other reasons
    //                 if (reason > 0) {
    //                     auto reasonbyte = static_cast<int8_t>(reason - 1);

    //                     UI::get().emplace<UILoginNotice>(reasonbyte, okhandler);
    //                 }

    //                 break;
    //         }
    _ as reason => @log.warn({ "reason": reason }, "login failed")
  }
  // }
}

fn fn_server_req() -> Unit {
  new_server_request_packet().dispatch()
}

fn new_server_request_packet() -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::SERVERLIST_REQUEST)
}

fn fn_tos() -> Unit {
  new_tos_packet().dispatch()
}

fn new_tos_packet() -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::ACCEPT_TOS)..write_byte(
    (1).to_byte(),
  )
}

fn parse_account(recv : @net.InPacket) -> Account!Error {
  recv.skip_short!()
  let accid = recv.read_int!()
  let female = recv.read_byte!()
  let admin = recv.read_bool!()
  recv.skip_byte!() // Admin
  recv.skip_byte!() // Country Code
  let name = recv.read_string!()
  recv.skip_byte!()
  let muted = recv.read_bool!()
  recv.skip_long!() // muted until
  recv.skip_long!() // creation date
  recv.skip_int!() // Remove "Select the world you want to play in"
  let pin = recv.read_bool!() // 0 - Enabled, 1 - Disabled
  let pic = recv.read_byte!() // 0 - Register, 1 - Ask, 2 - Disabled
  { accid, female, admin, name, muted, pin, pic }
}

struct Account {
  accid : Int
  female : Int
  admin : Bool
  name : String
  muted : Bool
  pin : Bool
  pic : Int
}

pub struct StatsEntry {
  name : String
  stats : Map[@MapleStat.Id, Int]
  mapid : Int
}

pub struct LookEntry {
  // bool female;
  skin : Int
  faceid : Int
  hairid : Int
  // std::map<int8_t, int32_t> equips;
  // std::map<int8_t, int32_t> maskedequips;
  // std::vector<int32_t> petids;
}

pub struct CharEntry {
  stats : StatsEntry
  look : LookEntry
  id : Int
}
