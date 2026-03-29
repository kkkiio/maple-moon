///|
/// Take a snapshot of the current canvas and save it to the specified path.
/// 
/// If the snapshot file already exists, compare it with the current canvas and fail if they don't match.
/// 
/// If the `UPDATE_CANVAS_SNAPS` environment variable is set to `"true"`, the snapshot file will be updated.
/// 
/// Use `visual_desc` to provide semantic expectation for the snapshot.
/// If snapshot is in update mode (`UPDATE_CANVAS_SNAPS=true` or snapshot file missing),
/// use vision model to assert semantic expectation.
pub async fn snapshot(path : String, visual_desc~ : String) -> Unit {
  let actual_buffer = to_buffer()
  let actual = actual_buffer.to_bytes()
  let update_snapshot = @sys.get_env_var("UPDATE_CANVAS_SNAPS") is Some("true")
  let should_write_snapshot = update_snapshot || !@fs.path_exists(path)
  if should_write_snapshot {
    guard @sys.get_env_var("OPENROUTER_API_KEY") is Some(api_key) &&
      api_key != "" else {
      fail(
        "visual_desc check requires OPENROUTER_API_KEY in environment, do you forget to load .env.test?",
      )
    }
    let verdict = snapshot_verdict(actual_buffer, visual_desc, api_key, path)
    let dir = @path.Path(path).dirname().to_string()
    @fs.create_dir(dir)
    if not(verdict.pass) {
      let ext = @path.Path(path).extname()
      let wrong_img_path = path.chop_suffix(ext).unwrap_or(path) +
        ".wrong" +
        ext
      @fs.write_bytes_to_file(wrong_img_path.to_string(), actual)
      let reason = if verdict.reason == "" {
        "<missing>"
      } else {
        verdict.reason
      }
      fail(
        "snapshot does not match expectation, new_img=\{wrong_img_path}, reason=\{reason}",
      )
    }
    @fs.write_bytes_to_file(path, actual)
  } else {
    let expected = @fs.read_file_to_bytes(path)
    if actual != expected &&
      not(
        png_buffers_equal_by_pixels(actual_buffer, Buffer::from_bytes(expected)),
      ) {
      fail(snapshot_mismatch_msg(path, actual, expected))
    }
  }
}

///|
const OPENROUTER_MODEL : String = "google/gemini-3.1-flash-lite-preview"

///|
async fn snapshot_verdict(
  actual_buffer : Buffer,
  expect : String,
  api_key : String,
  path : String,
) -> SnapshotExpectVerdict {
  let image_data_url = "data:image/png;base64,\{actual_buffer.to_base64()}"
  let messages : Json = [
    {
      "role": "system",
      "content": "You evaluate whether a partial screenshot from a 2D game matches an expectation. The image is only a local crop/frame, so judge only visible content and do not assume off-screen elements. Return strict XML only.",
    },
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "Context: this is a local screenshot of a running 2D game scene/UI. Expectation: \{expect}\n\nOutput exactly this XML structure and nothing else:\n<analysis>\n  <observations>visible facts from image only</observations>\n  <comparison>compare observations with expectation</comparison>\n  <verdict>\n    <pass>true|false</pass>\n    <reason>brief reason</reason>\n  </verdict>\n</analysis>",
        },
        { "type": "image_url", "imageUrl": { "url": image_data_url } },
      ],
    },
  ]
  let request_params : Json = {
    "model": OPENROUTER_MODEL,
    "temperature": 0,
    "messages": messages,
  }
  let raw : String = openrouter_chat_send(api_key, request_params.stringify()).wait()
  @log.debug("snapshot expect raw response", data={
    "path": path,
    "expect": expect,
    "raw_response": raw,
  })
  parse_snapshot_expect_xml(raw)
}

///|
priv struct SnapshotExpectVerdict {
  pass : Bool
  reason : String
}

///|
fn parse_snapshot_expect_xml(raw : String) -> SnapshotExpectVerdict raise {
  let (analysis_body, analysis_rest) = consume_xml_tag(raw, "analysis")
  guard analysis_rest.trim() == "" else {
    fail("snapshot expect XML has unexpected trailing content")
  }
  let (_, after_observations) = consume_xml_tag(analysis_body, "observations")
  let (_, after_comparison) = consume_xml_tag(after_observations, "comparison")
  let (verdict_body, after_verdict) = consume_xml_tag(
    after_comparison, "verdict",
  )
  guard after_verdict.trim() == "" else {
    fail("snapshot expect XML has unexpected content after <verdict>")
  }
  let (pass_text, after_pass) = consume_xml_tag(verdict_body, "pass")
  let (reason, after_reason) = consume_xml_tag(after_pass, "reason")
  guard after_reason.trim() == "" else {
    fail("snapshot expect XML verdict has unexpected extra content")
  }
  let pass = match pass_text.trim().to_string() {
    "true" => true
    "false" => false
    _ => fail("snapshot expect XML <pass> must be true or false")
  }
  { pass, reason: reason.trim().to_string() }
}

///|
fn consume_xml_tag(input : String, tag : String) -> (String, String) raise {
  let normalized = input.trim()
  let open = "<\{tag}>"
  let close = "</\{tag}>"
  let open_parts = normalized.split(open).to_array()
  guard open_parts is [prefix, after_open] else {
    fail("snapshot expect XML missing tag: \{open}")
  }
  guard prefix.trim() == "" else {
    fail("snapshot expect XML unexpected content before \{open}")
  }
  let close_parts = after_open.split(close).to_array()
  guard close_parts is [content, rest] else {
    fail("snapshot expect XML missing closing tag: \{close}")
  }
  (content.trim().to_string(), rest.to_string())
}

///|
extern "js" fn openrouter_chat_send(
  api_key : String,
  chat_generation_params_json : String,
) -> @js_async.Promise[String] =
  #| async (apiKey, chatGenerationParamsJson) => {
  #|   const { OpenRouter } = await import("@openrouter/sdk");
  #|   const openRouter = new OpenRouter({ apiKey });
  #|   const chatGenerationParams = JSON.parse(chatGenerationParamsJson);
  #|   const response = await openRouter.chat.send({
  #|     chatGenerationParams
  #|   });
  #|   const content = response?.choices?.[0]?.message?.content;
  #|   if (typeof content === "string") {
  #|     return content;
  #|   }
  #|   if (Array.isArray(content)) {
  #|     const text = content
  #|       .map((item) => (item && typeof item.text === "string" ? item.text : ""))
  #|       .filter(Boolean)
  #|       .join("\n");
  #|     if (text) return text;
  #|   }
  #|   if (content && typeof content === "object") {
  #|     return JSON.stringify(content);
  #|   }
  #|   throw new Error("empty response content");
  #| }

///|
pub extern "js" fn Buffer::to_base64(self : Buffer) -> String =
  #|(buf) => buf.toString("base64")

///|
pub extern "js" fn png_buffers_equal_by_pixels(
  actual : Buffer,
  expected : Buffer,
) -> Bool =
  #|(actual, expected) => {
  #|  const { createCanvas, Image } = require('canvas');
  #|  const toPixels = (buf) => {
  #|    const img = new Image();
  #|    img.src = buf;
  #|    const canvas = createCanvas(img.width, img.height);
  #|    const ctx = canvas.getContext('2d');
  #|    ctx.drawImage(img, 0, 0);
  #|    return {
  #|      width: img.width,
  #|      height: img.height,
  #|      data: ctx.getImageData(0, 0, img.width, img.height).data,
  #|    };
  #|  };
  #|  const lhs = toPixels(actual);
  #|  const rhs = toPixels(expected);
  #|  if (lhs.width !== rhs.width || lhs.height !== rhs.height) return false;
  #|  if (lhs.data.length !== rhs.data.length) return false;
  #|  for (let i = 0; i < lhs.data.length; i++) {
  #|    if (lhs.data[i] !== rhs.data[i]) return false;
  #|  }
  #|  return true;
  #|}
