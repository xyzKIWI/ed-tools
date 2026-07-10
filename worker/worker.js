// tools.kiwi-ai.uk → 反向代理 GitHub Pages 的 ed-tools 入口頁
// 使用者網址列保持 tools.kiwi-ai.uk，內容即時來自 xyzkiwi.github.io/ed-tools/
const ORIGIN = "https://xyzkiwi.github.io/ed-tools";

export default {
  async fetch(request) {
    const url = new URL(request.url);
    const target = ORIGIN + url.pathname + url.search;
    const resp = await fetch(target, {
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
