// Render frame strips of the lab's recipes in roblox-vfx's own browser simulator, headless.
//
//   node tools/render_previews.js [--skill ~/.claude/skills/roblox-vfx] [--three /path/three.min.js]
//
// Needs: Playwright with Chromium, the roblox-vfx skill installed, and Python (for sim/serve.py).
// The sim page loads three.js r128 from cdnjs; where that host is blocked, pass --three with a local
// copy (`npm pack three@0.128.0`, file package/build/three.min.js) and this script serves it in its place.
// Recipes go through SIM.fromRecipe (the repo's importer); strips land in library/previews/.
// The sim draws stock rbxasset textures as stand-ins (star / soft dot), so judge timing, size,
// colour and density here, and the exact texture look in Studio.
"use strict";
const { chromium } = require("playwright");
const { spawn } = require("child_process");
const fs = require("fs");
const os = require("os");
const path = require("path");

const arg = (k, d) => {
  const i = process.argv.indexOf(k);
  return i > 0 ? process.argv[i + 1] : d;
};
const LAB = path.resolve(__dirname, "..");
const SKILL = arg("--skill", path.join(os.homedir(), ".claude", "skills", "roblox-vfx"));
const THREE = arg("--three", null);
const PORT = Number(arg("--port", "8799"));
const OUT = path.join(LAB, "library", "previews");

const SHOTS = {
  // name: [times in seconds]
  SunAura: [0.3, 0.6, 1.0, 1.4, 1.8, 2.2],
  SunBurst: [0.1, 0.12, 0.18, 0.3, 0.5, 0.8],
  SunVictory: [0.12, 0.25, 0.5, 0.8, 1.1, 1.5],
};

(async () => {
  const server = spawn("python3", [path.join(SKILL, "sim", "serve.py"), String(PORT)], { stdio: "ignore" });
  await new Promise((r) => setTimeout(r, 1500));
  const browser = await chromium.launch({ args: ["--use-gl=swiftshader", "--enable-webgl", "--ignore-gpu-blocklist"] });
  try {
    const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
    page.on("pageerror", (e) => console.error("page error:", e.message));
    if (THREE) {
      const body = fs.readFileSync(THREE);
      await page.route("**/three.min.js", (route) => route.fulfill({ body, contentType: "application/javascript" }));
    }
    // roblox-vfx gap (found 2026-11-19): vfxrender.js draws stock rbxasset textures with stand-ins
    // "star4" and "soft_dot", but no generator writes those PNGs, so stock-texture recipes draw nothing.
    // Serve the skill's own closest generated textures in their place (upstream files untouched).
    const STANDIN = { "star4.png": "spark_star4.png", "soft_dot.png": "glow_soft.png" };
    await page.route(/\/textures\/(star4|soft_dot)\.png$/, (route) => {
      const file = STANDIN[path.basename(new URL(route.request().url()).pathname)];
      route.fulfill({ body: fs.readFileSync(path.join(SKILL, "sim", "textures", file)), contentType: "image/png" });
    });
    await page.goto(`http://127.0.0.1:${PORT}/`);
    // wait for the page's own first effect to finish loading, or it replaces ours mid-render
    await page.waitForFunction(() => window.app && window.VFXSIM && window.app.world, null, { timeout: 60000 });
    await page.waitForTimeout(1500);
    fs.mkdirSync(OUT, { recursive: true });
    const summary = {};
    for (const [name, times] of Object.entries(SHOTS)) {
      const rec = JSON.parse(fs.readFileSync(path.join(LAB, "library", "recipes", `${name}.json`), "utf8"));
      const res = await page.evaluate(async ({ rec, times }) => {
        const def = window.VFXSIM.fromRecipe(rec);
        // ground-level camera about 14 studs out, looking at the effect root (y = 3), dummy for scale
        def.camera = { pos: [9, 6, 11], at: [0, 3, 0], fov: 60 };
        def.duration = Math.max(def.duration, times[times.length - 1] + 0.2);
        window.app.load(def);
        await window.app.ready();
        const s = await window.app.strip(times, { cols: 6, w: 320, h: 180, label: rec.name + " " });
        return { png: s.png, metrics: s.metrics };
      }, { rec, times });
      fs.writeFileSync(path.join(OUT, `${name}.png`), Buffer.from(res.png.split(",")[1], "base64"));
      summary[name] = res.metrics.map((m) => ({ t: m.t, luma: Math.round(m.luma), sat: Math.round(m.sat * 100) / 100, hot: Math.round(m.hot * 1000) / 1000 }));
      console.log(name, JSON.stringify(summary[name]));
    }
    fs.writeFileSync(path.join(OUT, "metrics.json"), JSON.stringify(summary, null, 1) + "\n");
  } finally {
    await browser.close();
    server.kill();
  }
})();
