import fs from "node:fs";
import path from "node:path";
import { chromium } from "playwright";

function parseArgs(argv) {
  const args = {
    url: null,
    iterations: 3,
    pauseMs: 250,
    headless: true,
    screenshotDir: "output/web-game",
    profileDir: null,
    actionsFile: null,
    actionsJson: null,
    click: null,
    clickSelector: null,
  };
  for (let i = 2; i < argv.length; i++) {
    const arg = argv[i];
    const next = argv[i + 1];
    if (arg === "--url" && next) {
      args.url = next;
      i++;
    } else if (arg === "--iterations" && next) {
      args.iterations = parseInt(next, 10);
      i++;
    } else if (arg === "--pause-ms" && next) {
      args.pauseMs = parseInt(next, 10);
      i++;
    } else if (arg === "--headless" && next) {
      args.headless = next !== "0" && next !== "false";
      i++;
    } else if (arg === "--screenshot-dir" && next) {
      args.screenshotDir = next;
      i++;
    } else if (arg === "--profile-dir" && next) {
      args.profileDir = next;
      i++;
    } else if (arg === "--actions-file" && next) {
      args.actionsFile = next;
      i++;
    } else if (arg === "--actions-json" && next) {
      args.actionsJson = next;
      i++;
    } else if (arg === "--click" && next) {
      const parts = next.split(",").map((v) => parseFloat(v.trim()));
      if (parts.length === 2 && parts.every((v) => Number.isFinite(v))) {
        args.click = { x: parts[0], y: parts[1] };
      }
      i++;
    } else if (arg === "--click-selector" && next) {
      args.clickSelector = next;
      i++;
    }
  }
  if (!args.url) {
    throw new Error("--url is required");
  }
  return args;
}

const buttonNameToKey = {
  up: "ArrowUp",
  down: "ArrowDown",
  left: "ArrowLeft",
  right: "ArrowRight",
  enter: "Enter",
  space: "Space",
  a: "KeyA",
  b: "KeyB",
};

async function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function ensureDir(p) {
  fs.mkdirSync(p, { recursive: true });
}

function makeVirtualTimeShim() {
  return `(() => {
    const pending = new Set();
    const origSetTimeout = window.setTimeout.bind(window);
    const origSetInterval = window.setInterval.bind(window);
    const origRequestAnimationFrame = window.requestAnimationFrame.bind(window);

    window.__vt_pending = pending;

    window.setTimeout = (fn, t, ...rest) => {
      const task = {};
      pending.add(task);
      return origSetTimeout(() => {
        pending.delete(task);
        fn(...rest);
      }, t);
    };

    window.setInterval = (fn, t, ...rest) => {
      const task = {};
      pending.add(task);
      return origSetInterval(() => {
        fn(...rest);
      }, t);
    };

    window.requestAnimationFrame = (fn) => {
      const task = {};
      pending.add(task);
      return origRequestAnimationFrame((ts) => {
        pending.delete(task);
        fn(ts);
      });
    };

    window.advanceTime = (ms) => {
      return new Promise((resolve) => {
        const start = performance.now();
        function step(now) {
          if (now - start >= ms) return resolve();
          origRequestAnimationFrame(step);
        }
        origRequestAnimationFrame(step);
      });
    };

    window.__drainVirtualTimePending = () => pending.size;
  })();`;
}

async function getCanvasHandle(page) {
  const handle = await page.evaluateHandle(() => {
    let best = null;
    let bestArea = 0;
    for (const canvas of document.querySelectorAll("canvas")) {
      const area = (canvas.width || canvas.clientWidth || 0) * (canvas.height || canvas.clientHeight || 0);
      if (area > bestArea) {
        bestArea = area;
        best = canvas;
      }
    }
    return best;
  });
  return handle.asElement();
}

async function captureCanvasPngBase64(canvas) {
  return canvas.evaluate((c) => {
    if (!c || typeof c.toDataURL !== "function") return "";
    const data = c.toDataURL("image/png");
    const idx = data.indexOf(",");
    return idx === -1 ? "" : data.slice(idx + 1);
  });
}

async function isCanvasTransparent(canvas) {
  if (!canvas) return true;
  return canvas.evaluate((c) => {
    try {
      const w = c.width || c.clientWidth || 0;
      const h = c.height || c.clientHeight || 0;
      if (!w || !h) return true;
      const size = Math.max(1, Math.min(16, w, h));
      const probe = document.createElement("canvas");
      probe.width = size;
      probe.height = size;
      const ctx = probe.getContext("2d");
      if (!ctx) return true;
      ctx.drawImage(c, 0, 0, size, size);
      const data = ctx.getImageData(0, 0, size, size).data;
      for (let i = 3; i < data.length; i += 4) {
        if (data[i] !== 0) return false;
      }
      return true;
    } catch {
      return false;
    }
  });
}

async function captureScreenshot(page, canvas, outPath) {
  let buffer = null;
  let base64 = canvas ? await captureCanvasPngBase64(canvas) : "";
  if (base64) {
    buffer = Buffer.from(base64, "base64");
    const transparent = canvas ? await isCanvasTransparent(canvas) : false;
    if (transparent) buffer = null;
  }
  if (!buffer && canvas) {
    try {
      buffer = await canvas.screenshot({ type: "png" });
    } catch {
      buffer = null;
    }
  }
  if (!buffer) {
    const bbox = canvas ? await canvas.boundingBox() : null;
    if (bbox) {
      buffer = await page.screenshot({
        type: "png",
        omitBackground: false,
        clip: bbox,
      });
    } else {
      buffer = await page.screenshot({ type: "png", omitBackground: false });
    }
  }
  fs.writeFileSync(outPath, buffer);
}

class ConsoleErrorTracker {
  constructor() {
    this._seen = new Set();
    this._errors = [];
  }

  ingest(err) {
    const key = JSON.stringify(err);
    if (this._seen.has(key)) return;
    this._seen.add(key);
    this._errors.push(err);
  }

  drain() {
    const next = [...this._errors];
    this._errors = [];
    return next;
  }
}

class BadResponseTracker {
  constructor() {
    this._seen = new Set();
    this._bad = [];
  }

  ingest(resp) {
    const key = JSON.stringify(resp);
    if (this._seen.has(key)) return;
    this._seen.add(key);
    this._bad.push(resp);
  }

  drain() {
    const next = [...this._bad];
    this._bad = [];
    return next;
  }
}

async function stepFrames(page, frames) {
  const n = Math.max(1, Number(frames || 1));
  await page.evaluate(async (count) => {
    for (let i = 0; i < count; i++) {
      if (globalThis.$console && typeof globalThis.$console.step === "function") {
        await globalThis.$console.step(1);
      } else if (typeof globalThis.advanceTime === "function") {
        await globalThis.advanceTime(1000 / 60);
      } else {
        await new Promise((resolve) => requestAnimationFrame(() => resolve()));
      }
    }
  }, n);
}

function getByPath(obj, pathExpr) {
  if (!pathExpr) return obj;
  const parts = String(pathExpr)
    .split(".")
    .map((s) => s.trim())
    .filter(Boolean);
  let cur = obj;
  for (const part of parts) {
    if (cur == null) return undefined;
    if (Array.isArray(cur) && /^\d+$/.test(part)) {
      cur = cur[Number(part)];
      continue;
    }
    cur = cur[part];
  }
  return cur;
}

async function readStateJson(page) {
  const text = await page.evaluate(() => {
    if (typeof globalThis.render_game_to_text !== "function") return null;
    return globalThis.render_game_to_text();
  });
  if (!text) return null;
  try {
    return JSON.parse(text);
  } catch {
    return null;
  }
}

function matchWaitState(state, step) {
  if (!state) return false;
  const current = getByPath(state, step.path);
  if (Object.prototype.hasOwnProperty.call(step, "equals")) {
    return current === step.equals;
  }
  if (Object.prototype.hasOwnProperty.call(step, "not_equals")) {
    return current !== step.not_equals;
  }
  if (Array.isArray(step.in)) {
    return step.in.includes(current);
  }
  if (Array.isArray(step.not_in)) {
    return !step.not_in.includes(current);
  }
  return false;
}

async function doChoreography(page, canvas, steps, trace) {
  trace.push({ type: "sequence_start", total_steps: steps.length });
  for (const step of steps) {
    const type = step && typeof step === "object" ? step.type : null;
    if (type === "console_step") {
      const frames = step.frames || 1;
      await stepFrames(page, frames);
      trace.push({ type, frames });
      continue;
    }
    if (type === "sleep") {
      const ms = Number(step.ms || 0);
      await sleep(ms);
      trace.push({ type, ms });
      continue;
    }
    if (type === "console_ui_click") {
      const pkg = step.package;
      const name = step.name;
      const result = await page.evaluate(({ pkg, name }) => {
        if (!globalThis.$console || !globalThis.$console.ui) {
          return { ok: false, code: "CONSOLE_MISSING", message: "$console.ui is unavailable" };
        }
        return globalThis.$console.ui.click(pkg, name);
      }, { pkg, name });
      const frames = step.step_frames || 2;
      await stepFrames(page, frames);
      trace.push({ type, package: pkg, name, result, step_frames: frames });
      const strict = step.strict !== false;
      if (strict && result && result.code && result.code !== "QUEUED") {
        throw new Error(`console_ui_click failed: ${pkg}.${name}, code=${result.code}`);
      }
      continue;
    }
    if (type === "wait_state") {
      const maxFrames = Number(step.max_frames || 1800);
      const chunk = Math.max(1, Number(step.step_frames || 10));
      let matched = false;
      let last = null;
      for (let i = 0; i < maxFrames; i += chunk) {
        await stepFrames(page, chunk);
        last = await readStateJson(page);
        if (matchWaitState(last, step)) {
          matched = true;
          break;
        }
      }
      trace.push({
        type,
        path: step.path,
        equals: step.equals,
        not_equals: step.not_equals,
        matched,
      });
      if (!matched && step.strict !== false) {
        throw new Error(`wait_state timeout: path=${step.path}`);
      }
      continue;
    }
    if (type === "wait_ui") {
      const maxFrames = Number(step.max_frames || 1200);
      const chunk = Math.max(1, Number(step.step_frames || 10));
      let matched = false;
      const pkg = step.package;
      const name = step.name;
      for (let i = 0; i < maxFrames; i += chunk) {
        await stepFrames(page, chunk);
        const state = await readStateJson(page);
        const entries = Array.isArray(state?.clickable_ui_entries) ? state.clickable_ui_entries : [];
        if (entries.some((e) => e.package === pkg && e.name === name)) {
          matched = true;
          break;
        }
      }
      trace.push({ type, package: pkg, name, matched });
      if (!matched && step.strict !== false) {
        throw new Error(`wait_ui timeout: ${pkg}.${name}`);
      }
      continue;
    }

    const buttons = new Set(step.buttons || []);
    for (const button of buttons) {
      if (button === "left_mouse_button" || button === "right_mouse_button") {
        const bbox = canvas ? await canvas.boundingBox() : null;
        if (!bbox) continue;
        const x = typeof step.mouse_x === "number" ? step.mouse_x : bbox.width / 2;
        const y = typeof step.mouse_y === "number" ? step.mouse_y : bbox.height / 2;
        await page.mouse.move(bbox.x + x, bbox.y + y);
        await page.mouse.down({ button: button === "left_mouse_button" ? "left" : "right" });
      } else if (buttonNameToKey[button]) {
        await page.keyboard.down(buttonNameToKey[button]);
      }
    }

    const frames = step.frames || 1;
    await stepFrames(page, frames);

    for (const button of buttons) {
      if (button === "left_mouse_button" || button === "right_mouse_button") {
        await page.mouse.up({ button: button === "left_mouse_button" ? "left" : "right" });
      } else if (buttonNameToKey[button]) {
        await page.keyboard.up(buttonNameToKey[button]);
      }
    }
    trace.push({ type: "legacy_buttons", buttons: [...buttons], frames });
  }
}

async function main() {
  const args = parseArgs(process.argv);
  ensureDir(args.screenshotDir);

  let browser = null;
  let context = null;
  if (args.profileDir) {
    ensureDir(args.profileDir);
    context = await chromium.launchPersistentContext(args.profileDir, {
      channel: "chrome",
      headless: args.headless,
    });
  } else {
    browser = await chromium.launch({
      channel: "chrome",
      headless: args.headless,
    });
    context = await browser.newContext();
  }
  const page = context.pages().length > 0 ? context.pages()[0] : await context.newPage();
  const consoleErrors = new ConsoleErrorTracker();
  const badResponses = new BadResponseTracker();

  page.on("console", (msg) => {
    if (msg.type() !== "error") return;
    consoleErrors.ingest({ type: "console.error", text: msg.text() });
  });
  page.on("pageerror", (err) => {
    consoleErrors.ingest({ type: "pageerror", text: String(err) });
  });
  page.on("response", (resp) => {
    if (resp.status() < 400) return;
    badResponses.ingest({ status: resp.status(), url: resp.url() });
  });

  await page.addInitScript({ content: makeVirtualTimeShim() });
  await page.goto(args.url, { waitUntil: "domcontentloaded" });
  await page.waitForTimeout(500);
  await page.evaluate(() => {
    window.dispatchEvent(new Event("resize"));
  });

  let canvas = await getCanvasHandle(page);

  if (args.clickSelector) {
    try {
      await page.click(args.clickSelector, { timeout: 5000 });
      await page.waitForTimeout(250);
    } catch (err) {
      console.warn("Failed to click selector", args.clickSelector, err);
    }
  }
  let steps = null;
  if (args.actionsFile) {
    const raw = fs.readFileSync(args.actionsFile, "utf-8");
    const parsed = JSON.parse(raw);
    if (Array.isArray(parsed)) steps = parsed;
    if (parsed && Array.isArray(parsed.steps)) steps = parsed.steps;
  } else if (args.actionsJson) {
    const parsed = JSON.parse(args.actionsJson);
    if (Array.isArray(parsed)) steps = parsed;
    if (parsed && Array.isArray(parsed.steps)) steps = parsed.steps;
  } else if (args.click) {
    steps = [
      {
        buttons: ["left_mouse_button"],
        frames: 2,
        mouse_x: args.click.x,
        mouse_y: args.click.y,
      },
    ];
  }
  if (!steps) {
    throw new Error("Actions are required. Use --actions-file, --actions-json, or --click.");
  }

  for (let i = 0; i < args.iterations; i++) {
    const trace = [];
    if (!canvas) canvas = await getCanvasHandle(page);
    await doChoreography(page, canvas, steps, trace);
    await sleep(args.pauseMs);

    const shotPath = path.join(args.screenshotDir, `shot-${i}.png`);
    await captureScreenshot(page, canvas, shotPath);

    const text = await page.evaluate(() => {
      if (typeof window.render_game_to_text === "function") {
        return window.render_game_to_text();
      }
      return null;
    });
    if (text) {
      fs.writeFileSync(path.join(args.screenshotDir, `state-${i}.json`), text);
    }
    fs.writeFileSync(
      path.join(args.screenshotDir, `action-trace-${i}.json`),
      JSON.stringify(trace, null, 2)
    );

    const freshErrors = consoleErrors.drain();
    if (freshErrors.length) {
      fs.writeFileSync(
        path.join(args.screenshotDir, `errors-${i}.json`),
        JSON.stringify(freshErrors, null, 2)
      );
      break;
    }
    const bad = badResponses.drain();
    if (bad.length) {
      fs.writeFileSync(
        path.join(args.screenshotDir, `bad-responses-${i}.json`),
        JSON.stringify(bad, null, 2)
      );
      break;
    }
  }

  await context.close();
  if (browser) {
    await browser.close();
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
