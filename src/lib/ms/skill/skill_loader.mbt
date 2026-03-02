///|
/// Skill resource loader with two-level caching.
///
/// - Bundle cache: jobid.img -> Json (e.g., "0100.img" contains all warrior skills)
/// - Skill cache: skill_id -> SkillData

///|
/// Bundle-level cache: jobid.img -> raw JSON
let bundle_cache : Map[String, Json] = {}

///|
/// Skill-level cache: skill_id -> parsed SkillData
let skill_cache : Map[Int, SkillData] = {}

///|
/// Load error types
pub(all) suberror SkillLoadError {
  NOT_FOUND(Int)
  INVALID_DATA(String)
} derive(Show)

///|
pub impl Show for SkillLoadError with to_string(self) -> String {
  match self {
    NOT_FOUND(id) => "Skill not found: " + id.to_string()
    INVALID_DATA(msg) => "Invalid skill data: " + msg
  }
}

///|
/// Load a single skill with caching.
/// First loads the bundle, then extracts the specific skill.
pub async fn load_skill(id : Int) -> SkillData raise SkillLoadError {
  // 1. Check skill-level cache
  if skill_cache.get(id) is Some(cached) {
    return cached
  }

  // 2. Compute bundle key and strid
  let strid = @utils.stoi_left_pad0(id, 7)
  let jobid = strid.view(end_offset=3)
  let bundle_key = "\{jobid}.img"

  // 3. Get or load bundle (load full bundle, not individual skill)
  let bundle_json = match bundle_cache.get(bundle_key) {
    Some(cached) => cached
    None => {
      let loader = get_skill_loader()
      // Load the full bundle: [bundle_key] -> returns { "skill": { "2101002": {...} } }
      let json = loader.load_res_async([bundle_key]).value() catch {
          _ => raise INVALID_DATA("Failed to load bundle: " + bundle_key)
        }
      bundle_cache.set(bundle_key, json)
      json
    }
  }

  // 4. Extract skill data from bundle
  let skill_json = extract_skill_from_bundle(bundle_json, strid, id)

  // 5. Load text data (skill name, description)
  let text_json = get_string_loader()
    .load_res_async(["Skill.img", strid])
    .value() catch {
      _ => Json::null()
    }

  // 6. Parse and cache
  let data = parse_skill_data(id, skill_json, text_json)
  skill_cache.set(id, data)
  data
}

///|
/// Get cached skill data synchronously.
/// Returns None if not loaded yet.
pub fn get_cached_skill(id : Int) -> SkillData? {
  skill_cache.get(id)
}

///|
/// Preload a batch of skills (e.g., when character is created).
/// Groups by bundle to minimize network requests.
pub async fn preload_skills(
  skill_ids : Array[Int],
) -> Unit raise SkillLoadError {
  // Group by bundle
  let by_bundle : Map[String, Array[Int]] = {}
  for id in skill_ids {
    let strid = @utils.stoi_left_pad0(id, 7)
    let jobid = strid.view(end_offset=3)
    let bundle_key = "\{jobid}.img"
    by_bundle.get_or_init(bundle_key, fn() { [] }).push(id)
  }

  // Load each bundle and its skills
  for bundle_key, ids in by_bundle {
    // Preload bundle if not cached
    if not(bundle_cache.contains(bundle_key)) {
      let loader = get_skill_loader()
      // Load full bundle
      let json = loader.load_res_async([bundle_key]).value() catch {
          _ => raise INVALID_DATA("Failed to preload bundle: " + bundle_key)
        }
      bundle_cache.set(bundle_key, json)
    }

    // Load all skills in this bundle
    for id in ids {
      let _ = load_skill(id)
    }
  }
}

///|
/// Check if a skill is cached.
pub fn is_skill_cached(id : Int) -> Bool {
  skill_cache.contains(id)
}

///|
/// Get cache statistics for debugging.
pub fn skill_cache_stats() -> (Int, Int) {
  (bundle_cache.length(), skill_cache.length())
}

///|
/// Get the max level (master_level) for a skill from cached data.
/// Returns 20 if skill not cached (default max level).
pub fn get_skill_max_level(id : Int) -> Int {
  match skill_cache.get(id) {
    Some(data) => data.master_level
    None => 20
  }
}

///|
/// Extract skill JSON from bundle.
fn extract_skill_from_bundle(
  bundle_json : Json,
  strid : String,
  id : Int,
) -> Json raise SkillLoadError {
  guard bundle_json is Object(bundle_obj) else { raise NOT_FOUND(id) }
  guard bundle_obj.get("skill") is Some(Object(skill_obj)) else {
    raise NOT_FOUND(id)
  }
  guard skill_obj.get(strid) is Some(skill_data) else { raise NOT_FOUND(id) }
  skill_data
}

///|
/// Parse skill data from JSON.
fn parse_skill_data(
  id : Int,
  skill_json : Json,
  text_json : Json,
) -> SkillData raise SkillLoadError {
  // Parse skill resource data
  let skill_res : SkillNxResource = @json.from_json(skill_json) catch {
    _ => raise INVALID_DATA("Failed to parse skill JSON")
  }

  // Parse text data (fallback to empty if missing)
  let text_res : SkillTextResource = @json.from_json(text_json) catch {
    _ => { name: "", desc: "", levels: {} }
  }

  // Build SkillData from parsed resources
  SkillData::from_resources(id, skill_json, skill_res.simplify(), text_res)
}

///|
/// Create SkillData from parsed resources.
fn SkillData::from_resources(
  id : Int,
  skill_json : Json,
  skill_res : SkillResource,
  text_res : SkillTextResource,
) -> SkillData {
  SkillData::new(id, skill_json, skill_res, text_res)
}

///|
/// Clear all caches (for testing or memory pressure).
pub fn clear_skill_cache() -> Unit {
  bundle_cache.clear()
  skill_cache.clear()
}
