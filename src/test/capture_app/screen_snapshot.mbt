///|
/// Take a snapshot of the current canvas and save it to the specified path.
/// 
/// If the snapshot file already exists, compare it with the current canvas and fail if they don't match.
/// 
/// If the `UPDATE_CANVAS_SNAPS` environment variable is set to `"true"`, the snapshot file will be updated.
/// 
/// If `expect` is provided and snapshot is in update mode (`UPDATE_CANVAS_SNAPS=true` or snapshot file missing),
/// use OpenRouter vision model to assert semantic expectation.
pub async fn snapshot(path : String, expect? : String) -> Unit {
  let actual_buffer = to_buffer()
  let actual = actual_buffer.to_bytes()
  let update_snapshot = @sys.get_env_var("UPDATE_CANVAS_SNAPS") is Some("true")
  let should_write_snapshot = update_snapshot || !@fs.path_exists(path)
  if should_write_snapshot {
    if expect is Some(expect_text) {
      let api_key = require_openrouter_api_key()
      assert_snapshot_expect(actual_buffer, expect_text, api_key, path)
    }
    let dir = @path.Path(path).dirname().to_string()
    @fs.create_dir(dir)
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
fn require_openrouter_api_key() -> String raise {
  match @sys.get_env_var("OPENROUTER_API_KEY") {
    Some(v) if v != "" => v
    _ =>
      fail("snapshot expect check requires OPENROUTER_API_KEY in environment")
  }
}

///|
async fn assert_snapshot_expect(
  actual_buffer : Buffer,
  expect : String,
  api_key : String,
  path : String,
) -> Unit {
  let image_data_url = "data:image/png;base64,\{actual_buffer.to_base64()}"
  let messages : Json = [
    {
      "role": "system",
      "content": "You evaluate whether a partial screenshot from a 2D game matches an expectation. The image is only a local crop/frame, so judge only visible content and do not assume off-screen elements. Return strict JSON only.",
    },
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "Context: this is a local screenshot of a running 2D game scene/UI. Expectation: \{expect}",
        },
        { "type": "image_url", "imageUrl": { "url": image_data_url } },
      ],
    },
  ]
  let request_params : Json = {
    "model": OPENROUTER_MODEL,
    "temperature": 0,
    "responseFormat": {
      "type": "json_schema",
      "jsonSchema": {
        "name": "snapshot_expect_verdict",
        "strict": true,
        "schema": {
          "type": "object",
          "properties": {
            "pass": { "type": "boolean" },
            "reason": { "type": "string" },
          },
          "required": ["pass", "reason"],
          "additionalProperties": false,
        },
      },
    },
    "messages": messages,
  }
  let raw : String = openrouter_chat_send(api_key, request_params.stringify()).wait()
  @log.debug("snapshot expect raw response", data={
    "path": path,
    "expect": expect,
    "raw_response": raw,
  })
  let parsed = @json.parse(raw) catch {
    _ =>
      fail(
        "snapshot expect check returned invalid JSON, path=\{path}, raw=\{raw}",
      )
  }
  match parsed {
    { "pass": True, "reason": String(_), .. } => ()
    { "pass": False, "reason": String(reason), .. } =>
      fail("snapshot expect mismatch: \{path}, reason=\{reason}")
    { "pass": False, .. } =>
      fail("snapshot expect mismatch: \{path}, reason=<missing>")
    _ =>
      fail(
        "snapshot expect check returned unexpected payload, path=\{path}, payload=\{raw}",
      )
  }
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
