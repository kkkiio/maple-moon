pub struct StatsEntry {
  name : String
  stats : Map[@MapleStat.Id, Int]
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
