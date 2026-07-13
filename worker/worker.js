// tools.kiwi-ai.uk → 反向代理 GitHub Pages
// 使用者網址列保持 tools.kiwi-ai.uk，內容即時來自 xyzkiwi.github.io
// 短路徑對應各工具 repo 的 Pages；其餘路徑走 ed-tools 入口頁
const TOOLS = {
  "/icd10": "https://xyzkiwi.github.io/icd10-ed-quickref",
  "/abx": "https://xyzkiwi.github.io/abx-tool",
  "/peds": "https://xyzkiwi.github.io/peds-dose",
};
const HUB = "https://xyzkiwi.github.io/ed-tools";

export default {
  async fetch(request) {
    const url = new URL(request.url);
    let origin = HUB;
    let path = url.pathname;
    for (const [prefix, target] of Object.entries(TOOLS)) {
      if (path === prefix) {
        // 少了尾斜線會讓頁內相對路徑解析錯層，先補上再進來
        return Response.redirect(url.origin + prefix + "/" + url.search, 301);
      }
      if (path.startsWith(prefix + "/")) {
        origin = target;
        path = path.slice(prefix.length);
        break;
      }
    }
    const resp = await fetch(origin + path + url.search, {
      method: request.method,
      headers: request.headers,
      redirect: "follow",
    });
    // 原樣回傳（含 content-type），只補一個快取上限避免舊版黏太久
    const out = new Response(resp.body, resp);
    out.headers.set("Cache-Control", "public, max-age=300");
    return out;
  },
};
