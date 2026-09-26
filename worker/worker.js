// tools.kiwi-ai.uk → 反向代理 GitHub Pages
// 使用者網址列保持 tools.kiwi-ai.uk，內容即時來自 xyzkiwi.github.io
// 短路徑對應各工具 repo 的 Pages；其餘路徑走 ed-tools 入口頁
const TOOLS = {
  "/icd10": "https://xyzkiwi.github.io/icd10-ed-quickref",
  "/abx": "https://xyzkiwi.github.io/abx-tool",
  "/peds": "https://xyzkiwi.github.io/peds-dose",
  "/heparin": "https://xyzkiwi.github.io/heparin-tool",
  "/calc": "https://xyzkiwi.github.io/ed-calc",
};
const HUB = "https://xyzkiwi.github.io/ed-tools";

// Static GitHub Pages only needs cache negotiation and range request headers.
// In particular, never forward browser cookies or Authorization to another origin.
const UPSTREAM_REQUEST_HEADERS = [
  "accept",
  "accept-encoding",
  "if-match",
  "if-none-match",
  "if-modified-since",
  "if-unmodified-since",
  "if-range",
  "range",
];

const SECURITY_HEADERS = {
  "Strict-Transport-Security": "max-age=31536000",
  "X-Content-Type-Options": "nosniff",
  "X-Frame-Options": "SAMEORIGIN",
  "Referrer-Policy": "strict-origin-when-cross-origin",
  "Permissions-Policy": "camera=(), microphone=(), geolocation=(), payment=(), usb=()",
  "X-Permitted-Cross-Domain-Policies": "none",
};

// The ICD-10 app currently contains inline CSS/JS and opens its feedback form
// as a normal link. Cloudflare Web Analytics loads its script and sends its
// beacon to the two explicitly allowed Cloudflare origins below.
// Other proxied apps do not receive a CSP until each one has been compatibility-tested.
const ICD10_CSP = [
  "default-src 'self'",
  "base-uri 'none'",
  "object-src 'none'",
  "frame-ancestors 'self'",
  "script-src 'self' 'unsafe-inline' https://static.cloudflareinsights.com",
  "style-src 'self' 'unsafe-inline'",
  "img-src 'self' data:",
  "font-src 'self' data:",
  "connect-src 'self' https://cloudflareinsights.com",
  "form-action 'self'",
  "worker-src 'self' blob:",
  "manifest-src 'self'",
  "upgrade-insecure-requests",
].join("; ");

function upstreamHeaders(request) {
  const headers = new Headers();
  for (const name of UPSTREAM_REQUEST_HEADERS) {
    const value = request.headers.get(name);
    if (value !== null) headers.set(name, value);
  }
  return headers;
}

function isIcd10Path(pathname) {
  return pathname === "/icd10" || pathname.startsWith("/icd10/");
}

function securedResponse(response, pathname) {
  const headers = new Headers(response.headers);

  // An upstream cookie must not become a tools.kiwi-ai.uk cookie.
  headers.delete("set-cookie");
  for (const [name, value] of Object.entries(SECURITY_HEADERS)) {
    headers.set(name, value);
  }

  if (isIcd10Path(pathname)) {
    headers.set("Referrer-Policy", "no-referrer");
  }

  const contentType = headers.get("content-type") || "";
  if (isIcd10Path(pathname) && contentType.toLowerCase().includes("text/html")) {
    headers.set("Content-Security-Policy", ICD10_CSP);
  }

  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}

function redirect(location, status) {
  return new Response(null, { status, headers: { Location: location } });
}

function fetchUpstream(request, target) {
  return fetch(target, {
    method: request.method,
    headers: upstreamHeaders(request),
    redirect: "follow",
  });
}

function badGateway(pathname) {
  return securedResponse(
    new Response("Bad Gateway", {
      status: 502,
      headers: {
        "Cache-Control": "no-store",
        "Content-Type": "text/plain; charset=utf-8",
      },
    }),
    pathname,
  );
}

// 下載類：代理 GitHub Release 的固定檔名資產，讓安裝包也走本網域（院內網擋 github.io）
// 用 releases/latest/download/ 永久連結，發新版不必回來改這裡，
// 但每次發 release 都要記得附一份固定檔名（不帶版號）的 zip，否則這條會 404。
const DOWNLOADS = {
  "/medcloud.zip":
    "https://github.com/xyzKIWI/CloudMedicationHelper/releases/latest/download/CloudMedicationHelper.zip",
};

export default {
  async fetch(request) {
    const url = new URL(request.url);
    let origin = HUB;
    let path = url.pathname;

    if (url.protocol !== "https:") {
      const secureUrl = new URL(url);
      secureUrl.protocol = "https:";
      return securedResponse(redirect(secureUrl.toString(), 308), path);
    }

    if (request.method !== "GET" && request.method !== "HEAD") {
      return securedResponse(
        new Response("Method Not Allowed", {
          status: 405,
          headers: {
            Allow: "GET, HEAD",
            "Cache-Control": "no-store",
            "Content-Type": "text/plain; charset=utf-8",
          },
        }),
        path,
      );
    }

    const download = DOWNLOADS[path];
    if (download) {
      let resp;
      try {
        resp = await fetchUpstream(request, download);
      } catch {
        return badGateway(path);
      }
      const out = new Response(resp.body, resp);
      out.headers.set("Content-Disposition", `attachment; filename="${download.split("/").pop()}"`);
      out.headers.set("Cache-Control", resp.status >= 500 ? "no-store" : "public, max-age=300");
      return securedResponse(out, path);
    }

    for (const [prefix, target] of Object.entries(TOOLS)) {
      if (path === prefix) {
        // 少了尾斜線會讓頁內相對路徑解析錯層，先補上再進來
        return securedResponse(redirect(url.origin + prefix + "/" + url.search, 301), path);
      }
      if (path.startsWith(prefix + "/")) {
        origin = target;
        path = path.slice(prefix.length);
        break;
      }
    }
    let resp;
    try {
      resp = await fetchUpstream(request, origin + path + url.search);
    } catch {
      return badGateway(url.pathname);
    }
    // 原樣回傳（含 content-type），只補一個快取上限避免舊版黏太久
    const out = new Response(resp.body, resp);
    out.headers.set("Cache-Control", resp.status >= 500 ? "no-store" : "public, max-age=300");
    return securedResponse(out, url.pathname);
  },
};
