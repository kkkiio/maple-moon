#!/usr/bin/env node

import fs from "node:fs";
import http from "node:http";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { chromium } from "playwright";
import sharp from "sharp";

const root = process.cwd();
const rawArgs = process.argv.slice(2);
const moon = process.env.MOON_BIN ?? path.join(os.homedir(), ".moon/bin/moon");
const testsRoot = "src/tests";
const helperTestPackages = new Set(["capture_app", "mock_server"]);

let updateSnapshots = process.env.UPDATE_CANVAS_SNAPS === "true";
let listOnly = false;
const testTargets = [];
for (const arg of rawArgs) {
  if (arg === "--update") {
    updateSnapshots = true;
  } else if (arg === "--list") {
    listOnly = true;
  } else {
    testTargets.push(arg);
  }
}

const selectedTestTargets = testTargets.length > 0 ?
  testTargets :
  discoverWebGpuSnapshotTestTargets();

if (selectedTestTargets.length === 0) {
  console.error(`no WebGPU snapshot test packages found under ${testsRoot}`);
  process.exit(1);
}

if (listOnly) {
  for (const target of selectedTestTargets) {
    console.log(target);
  }
  process.exit(0);
}

const build = spawnSync(
  moon,
  ["test", "--target", "js", "--build-only", ...selectedTestTargets],
  { cwd: root, encoding: "utf8", maxBuffer: 128 * 1024 * 1024 },
);
process.stdout.write(build.stdout ?? "");
process.stderr.write(build.stderr ?? "");
if (build.status !== 0) {
  process.exit(build.status ?? 1);
}

const buildInfo = parseBuildOnlyOutput(build.stdout ?? "");
const server = createServer();
await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
const { port } = server.address();

const browser = await chromium.launch({
  channel: "chrome",
  headless: true,
  args: ["--enable-unsafe-webgpu"],
});

let failed = false;
try {
  for (let i = 0; i < buildInfo.artifacts_path.length; i += 1) {
    const artifactPath = buildInfo.artifacts_path[i];
    const filterArg = buildInfo.test_filter_args[i] ?? "{}";
    const entries = flattenTestEntries(filterArg);
    if (entries.length === 0) {
      continue;
    }
    const ok = await runArtifact({
      browser,
      port,
      artifactPath,
      entries,
      updateSnapshots,
    });
    failed = failed || !ok;
  }
} finally {
  await browser.close();
  server.close();
}

process.exit(failed ? 1 : 0);

function parseBuildOnlyOutput(stdout) {
  for (const line of stdout.trim().split(/\r?\n/).reverse()) {
    if (!line.startsWith("{")) {
      continue;
    }
    const parsed = JSON.parse(line);
    if (Array.isArray(parsed.artifacts_path)) {
      return parsed;
    }
  }
  throw new Error("moon test --build-only did not print artifacts_path JSON");
}

function discoverWebGpuSnapshotTestTargets() {
  const rootDir = path.join(root, testsRoot);
  if (!fs.existsSync(rootDir)) {
    return [];
  }
  return fs.readdirSync(rootDir, { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name)
    .filter((name) => !helperTestPackages.has(name))
    .map((name) => path.posix.join(testsRoot, name))
    .filter((target) => fs.existsSync(path.join(root, target, "moon.pkg")))
    .filter((target) => packageContainsSnapshotCall(path.join(root, target)))
    .sort();
}

function packageContainsSnapshotCall(packageDir) {
  for (const filePath of listMoonBitFiles(packageDir)) {
    if (fs.readFileSync(filePath, "utf8").includes("@capture_app.snapshot(")) {
      return true;
    }
  }
  return false;
}

function listMoonBitFiles(dir) {
  const files = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (entry.name === "__snapshot__") {
      continue;
    }
    const filePath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...listMoonBitFiles(filePath));
    } else if (entry.isFile() && entry.name.endsWith(".mbt")) {
      files.push(filePath);
    }
  }
  return files;
}

function flattenTestEntries(filterArg) {
  const parsed = JSON.parse(filterArg);
  const entries = [];
  const seen = new Set();
  for (const [file, ranges] of parsed.file_and_index ?? []) {
    for (const range of ranges) {
      for (let index = range.start; index < range.end; index += 1) {
        const key = `${file}:${index}`;
        if (seen.has(key)) {
          continue;
        }
        seen.add(key);
        entries.push([file, index]);
      }
    }
  }
  return entries;
}

async function runArtifact({ browser, port, artifactPath, entries, updateSnapshots }) {
  let ok = true;
  for (const entry of entries) {
    ok = await runArtifactEntries({
      browser,
      port,
      artifactPath,
      entries: [entry],
      updateSnapshots,
    }) && ok;
  }
  return ok;
}

async function runArtifactEntries({ browser, port, artifactPath, entries, updateSnapshots }) {
  const page = await browser.newPage();
  const actualResults = [];
  const pageErrors = [];
  const resourceErrors = new Set();
  let collectingActual = false;

  page.on("pageerror", (err) => {
    pageErrors.push(err.stack || err.message);
  });
  page.on("requestfailed", (request) => {
    resourceErrors.add(
      `request failed: ${request.method()} ${request.url()} ${request.failure()?.errorText ?? ""}`,
    );
  });
  page.on("response", (response) => {
    if (response.status() >= 400) {
      resourceErrors.add(`HTTP ${response.status()}: ${response.url()}`);
    }
  });
  page.on("console", (msg) => {
    const text = msg.text();
    if (collectingActual && text.startsWith("{\"package\":")) {
      actualResults.push(JSON.parse(text));
    }
    if (msg.type() === "error" && !text.includes("Failed to load resource")) {
      console.error(text);
    }
  });

  await installBrowserTestRuntime(page, updateSnapshots);
  const scriptUrl = `/__artifact?path=${encodeURIComponent(artifactPath)}`;
  await page.goto(`http://127.0.0.1:${port}/?script=${encodeURIComponent(scriptUrl)}`, {
    waitUntil: "load",
  });

  const hasDriver = await page.evaluate(() => {
    return typeof globalThis.exports?.moonbit_test_driver_internal_execute === "function";
  });
  if (!hasDriver) {
    console.error(`missing MoonBit test driver export in ${artifactPath}`);
    await page.close();
    return false;
  }

  await page.evaluate((testEntries) => {
    globalThis.__MAPLE_DEFER_SNAPSHOTS = true;
    globalThis.__MAPLE_DEFERRED_SNAPSHOTS = [];
    globalThis.exports.moonbit_test_driver_internal_execute(testEntries);
  }, entries);
  await waitForWebGpuAssets(page);
  for (const error of await collectWebGpuImageErrors(page)) {
    resourceErrors.add(error);
  }

  collectingActual = true;
  await page.evaluate((testEntries) => {
    globalThis.__MAPLE_DEFER_SNAPSHOTS = false;
    globalThis.__MAPLE_EXTERNAL_SNAPSHOT_CHECK = true;
    globalThis.__MAPLE_DEFERRED_SNAPSHOTS = [];
    globalThis.exports.moonbit_test_driver_internal_execute(testEntries);
    globalThis.exports.moonbit_test_driver_finish?.();
  }, entries);
  await waitForWebGpuAssets(page);
  for (const error of await collectWebGpuImageErrors(page)) {
    resourceErrors.add(error);
  }
  await page.waitForTimeout(100);
  collectingActual = false;

  await page.close();

  for (const error of pageErrors) {
    console.error(error);
  }
  for (const error of resourceErrors) {
    console.error(error);
  }
  for (const result of actualResults) {
    const message = result.message ?? "";
    if (message !== "") {
      console.error(
        `${result.package} ${result.filename}:${result.index} ${result.test_name}: ${message}`,
      );
    }
  }
  if (actualResults.length === 0) {
    console.error(`no MoonBit test results captured for ${artifactPath}`);
  }
  return pageErrors.length === 0 &&
    resourceErrors.size === 0 &&
    actualResults.length > 0 &&
    actualResults.every((result) => (result.message ?? "") === "");
}

async function collectWebGpuImageErrors(page) {
  return await page.evaluate(() => {
    const rt = globalThis.__selene_webgpu_runtime;
    if (!rt?.imageCache) {
      return [];
    }
    return Array.from(rt.imageCache.entries())
      .filter(([, record]) => record?.state === "error")
      .map(([path]) => `WebGPU image load failed: ${path}`);
  });
}

async function installBrowserTestRuntime(page, updateSnapshots) {
  await page.addInitScript(({ env }) => {
    globalThis.exports = {};
    globalThis.process = {
      argv: ["node", "moon-webgpu-test", JSON.stringify({ file_and_index: [] })],
      env,
      exit: (code) => {
        throw new Error(`process.exit ${code}`);
      },
    };
    globalThis.__MAPLE_EXTERNAL_SNAPSHOT_CHECK = false;
    globalThis.Buffer = {
      from: (value) => {
        if (value instanceof Uint8Array) {
          return value;
        }
        return new Uint8Array(Array.from(value ?? []));
      },
    };

    const syncRequest = (method, url, body) => {
      const xhr = new XMLHttpRequest();
      xhr.open(method, url, false);
      if (body != null) {
        xhr.setRequestHeader("content-type", "application/json");
      }
      xhr.send(body ?? null);
      if (xhr.status < 200 || xhr.status >= 300) {
        throw new Error(`${method} ${url} -> ${xhr.status}: ${xhr.responseText}`);
      }
      return xhr.responseText;
    };
    const bytesFromBase64 = (base64) => {
      const binary = atob(base64);
      const out = new Uint8Array(binary.length);
      for (let i = 0; i < binary.length; i += 1) {
        out[i] = binary.charCodeAt(i) & 0xff;
      }
      return out;
    };

    globalThis.require = (name) => {
      if (name !== "fs" && name !== "node:fs") {
        throw new Error(`unsupported browser test require: ${name}`);
      }
      return {
        readFileSync: (filePath) =>
          bytesFromBase64(syncRequest(
            "GET",
            `/__fs/read?path=${encodeURIComponent(filePath)}`,
          )),
        writeFileSync: (filePath, content) => {
          syncRequest("POST", "/__fs/write", JSON.stringify({
            path: filePath,
            bytes: Array.from(content ?? []),
          }));
        },
        existsSync: (filePath) =>
          syncRequest("GET", `/__fs/exists?path=${encodeURIComponent(filePath)}`) === "1",
        mkdirSync: (filePath) => {
          syncRequest("POST", `/__fs/mkdir?path=${encodeURIComponent(filePath)}`);
        },
        readdirSync: (filePath) =>
          JSON.parse(syncRequest(
            "GET",
            `/__fs/readdir?path=${encodeURIComponent(filePath)}`,
          )),
        statSync: (filePath) => {
          const stat = JSON.parse(syncRequest(
            "GET",
            `/__fs/stat?path=${encodeURIComponent(filePath)}`,
          ));
          return {
            isDirectory: () => stat.type === "dir",
            isFile: () => stat.type === "file",
          };
        },
        rmSync: (filePath) => {
          syncRequest("POST", `/__fs/rm?path=${encodeURIComponent(filePath)}`);
        },
        unlinkSync: (filePath) => {
          syncRequest("POST", `/__fs/unlink?path=${encodeURIComponent(filePath)}`);
        },
      };
    };
  }, {
    env: {
      ...process.env,
      UPDATE_CANVAS_SNAPS: updateSnapshots ? "true" : "",
    },
  });
}

async function waitForWebGpuAssets(page) {
  await page.waitForFunction(() => {
    const rt = globalThis.__selene_webgpu_runtime;
    if (!rt) {
      return true;
    }
    if (!rt.ready) {
      return false;
    }
    const records = Array.from(rt.imageCache?.values?.() ?? []);
    return records.every((record) => record.state !== "loading");
  }, null, { timeout: 15000 });
}

function createServer() {
  return http.createServer((req, res) => {
    const url = new URL(req.url, "http://127.0.0.1");
    try {
      if (url.pathname === "/") {
        const script = url.searchParams.get("script") ?? "";
        return send(res, 200, html(script), "text/html");
      }
      if (url.pathname === "/__artifact") {
        const artifactPath = url.searchParams.get("path") ?? "";
        return send(
          res,
          200,
          stripMoonBitAutoRun(readSafeFile(artifactPath, root)),
          "text/javascript",
        );
      }
      if (url.pathname.startsWith("/__fs/")) {
        return handleFs(url, req, res);
      }
      if (url.pathname === "/__snapshot/check") {
        return handleSnapshotCheck(req, res);
      }
      const filePath = path.resolve(root, decodeURIComponent(url.pathname.slice(1)));
      if (!filePath.startsWith(root) || !fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
        return send(res, 404, "not found");
      }
      res.writeHead(200, { "content-type": contentType(filePath) });
      fs.createReadStream(filePath).pipe(res);
    } catch (err) {
      send(res, 500, err.stack || String(err));
    }
  });
}

function handleSnapshotCheck(req, res) {
  const chunks = [];
  req.on("data", (chunk) => chunks.push(chunk));
  req.on("end", async () => {
    try {
      const body = JSON.parse(Buffer.concat(chunks).toString("utf8"));
      const snapshotPath = path.resolve(root, body.path ?? "");
      if (!snapshotPath.startsWith(root)) {
        return sendJson(res, 403, { ok: false, message: "snapshot path is outside project root" });
      }
      const actual = Buffer.from(body.bytes ?? []);
      const update = process.env.UPDATE_CANVAS_SNAPS === "true" || updateSnapshots;
      if (update || !fs.existsSync(snapshotPath)) {
        fs.mkdirSync(path.dirname(snapshotPath), { recursive: true });
        fs.writeFileSync(snapshotPath, actual);
        return sendJson(res, 200, { ok: true });
      }
      const expected = fs.readFileSync(snapshotPath);
      if (await pngPixelsEqual(actual, expected)) {
        return sendJson(res, 200, { ok: true });
      }
      const wrongPath = wrongSnapshotPath(snapshotPath);
      fs.writeFileSync(wrongPath, actual);
      return sendJson(res, 200, {
        ok: false,
        message: `snapshot mismatch: ${path.relative(root, snapshotPath)}, new snapshot saved to: ${path.relative(root, wrongPath)}`,
      });
    } catch (err) {
      return sendJson(res, 500, { ok: false, message: err.stack || String(err) });
    }
  });
}

async function pngPixelsEqual(actual, expected) {
  const left = await sharp(actual).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const right = await sharp(expected).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  if (
    left.info.width !== right.info.width ||
    left.info.height !== right.info.height ||
    left.info.channels !== right.info.channels
  ) {
    return false;
  }
  if (Buffer.compare(left.data, right.data) === 0) {
    return true;
  }
  const channels = left.info.channels;
  let mismatchedPixels = 0;
  let maxChannelDelta = 0;
  for (let i = 0; i < left.data.length; i += channels) {
    let equal = true;
    for (let channel = 0; channel < channels; channel += 1) {
      if (left.data[i + channel] !== right.data[i + channel]) {
        equal = false;
        break;
      }
    }
    if (equal) {
      continue;
    }
    const expectedTransparent = right.data[i + 3] === 0;
    const actualOpaqueBlack = left.data[i] === 0 &&
      left.data[i + 1] === 0 &&
      left.data[i + 2] === 0 &&
      left.data[i + 3] === 255;
    if (channels === 4 && expectedTransparent && actualOpaqueBlack) {
      continue;
    }
    const actualOpaque = channels === 4 && left.data[i + 3] === 255;
    const rgbClose = Math.abs(left.data[i] - right.data[i]) <= 1 &&
      Math.abs(left.data[i + 1] - right.data[i + 1]) <= 1 &&
      Math.abs(left.data[i + 2] - right.data[i + 2]) <= 1;
    if (actualOpaque && rgbClose) {
      continue;
    }
    mismatchedPixels += 1;
    for (let channel = 0; channel < channels; channel += 1) {
      maxChannelDelta = Math.max(
        maxChannelDelta,
        Math.abs(left.data[i + channel] - right.data[i + channel]),
      );
    }
  }
  const pixelCount = left.info.width * left.info.height;
  if (mismatchedPixels <= 64) {
    return true;
  }
  return mismatchedPixels <= Math.ceil(pixelCount * 0.002) &&
    maxChannelDelta <= 64;
}

function wrongSnapshotPath(snapshotPath) {
  const ext = path.extname(snapshotPath);
  if (ext.length === 0) {
    return `${snapshotPath}.wrong`;
  }
  return `${snapshotPath.slice(0, -ext.length)}.wrong${ext}`;
}

function html(script) {
  return `<!doctype html><meta charset="utf-8"><link rel="icon" href="data:,"><canvas id="canvas" width="800" height="600"></canvas><script src="${script}"></script>`;
}

function stripMoonBitAutoRun(source) {
  return source.replace(/\(\(\) => \{\s*const test_params =[\s\S]*?\n\}\)\(\);\n(?=exports\.moonbit_test_driver_finish\s*=)/, "");
}

function handleFs(url, req, res) {
  const filePath = path.resolve(root, url.searchParams.get("path") ?? "");
  if (!filePath.startsWith(root)) {
    return send(res, 403, "outside project root");
  }
  if (url.pathname === "/__fs/read") {
    return send(res, 200, fs.readFileSync(filePath).toString("base64"));
  }
  if (url.pathname === "/__fs/exists") {
    return send(res, 200, fs.existsSync(filePath) ? "1" : "0");
  }
  if (url.pathname === "/__fs/mkdir") {
    fs.mkdirSync(filePath, { recursive: true });
    return send(res, 200, "1");
  }
  if (url.pathname === "/__fs/readdir") {
    return send(res, 200, JSON.stringify(fs.readdirSync(filePath)), "application/json");
  }
  if (url.pathname === "/__fs/stat") {
    const stat = fs.statSync(filePath);
    return send(
      res,
      200,
      JSON.stringify({ type: stat.isDirectory() ? "dir" : "file" }),
      "application/json",
    );
  }
  if (url.pathname === "/__fs/rm") {
    fs.rmSync(filePath, { recursive: true, force: true });
    return send(res, 200, "1");
  }
  if (url.pathname === "/__fs/unlink") {
    fs.rmSync(filePath, { force: true });
    return send(res, 200, "1");
  }
  if (url.pathname === "/__fs/write") {
    const chunks = [];
    req.on("data", (chunk) => chunks.push(chunk));
    req.on("end", () => {
      const body = JSON.parse(Buffer.concat(chunks).toString("utf8"));
      const outPath = path.resolve(root, body.path ?? "");
      if (!outPath.startsWith(root)) {
        return send(res, 403, "outside project root");
      }
      fs.mkdirSync(path.dirname(outPath), { recursive: true });
      fs.writeFileSync(outPath, Buffer.from(body.bytes ?? []));
      send(res, 200, "1");
    });
    return;
  }
  send(res, 404, "unknown fs endpoint");
}

function readSafeFile(filePath, rootPath) {
  const resolved = path.resolve(filePath);
  if (!resolved.startsWith(rootPath)) {
    throw new Error(`artifact is outside project root: ${filePath}`);
  }
  return fs.readFileSync(resolved, "utf8");
}

function send(res, status, body, type = "text/plain") {
  res.writeHead(status, {
    "content-type": type,
    "access-control-allow-origin": "*",
  });
  res.end(body);
}

function sendJson(res, status, body) {
  send(res, status, JSON.stringify(body), "application/json");
}

function contentType(filePath) {
  switch (path.extname(filePath).toLowerCase()) {
    case ".js":
      return "text/javascript";
    case ".json":
      return "application/json";
    case ".png":
      return "image/png";
    case ".ttf":
      return "font/ttf";
    default:
      return "application/octet-stream";
  }
}
