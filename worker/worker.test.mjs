import assert from "node:assert/strict";
import test, { afterEach } from "node:test";

import worker from "./worker.js";

const nativeFetch = globalThis.fetch;

afterEach(() => {
  globalThis.fetch = nativeFetch;
});

function stubFetch(handler) {
  const calls = [];
  globalThis.fetch = async (input, init = {}) => {
    calls.push({ input: String(input), init });
    return handler(input, init);
  };
  return calls;
}

function assertGenericSecurityHeaders(
  response,
  expectedReferrerPolicy = "strict-origin-when-cross-origin",
) {
  assert.equal(
    response.headers.get("strict-transport-security"),
    "max-age=31536000",
  );
  assert.equal(response.headers.get("x-content-type-options"), "nosniff");
  assert.equal(response.headers.get("x-frame-options"), "SAMEORIGIN");
  assert.equal(response.headers.get("referrer-policy"), expectedReferrerPolicy);
  assert.equal(
    response.headers.get("permissions-policy"),
    "camera=(), microphone=(), geolocation=(), payment=(), usb=()",
  );
  assert.equal(response.headers.get("x-permitted-cross-domain-policies"), "none");
}

function assertIcd10SecurityHeaders(response) {
  assertGenericSecurityHeaders(response, "no-referrer");
}

test("HTTP is redirected to the same HTTPS path and query with 308", async () => {
  const calls = stubFetch(() => {
    throw new Error("upstream must not be called before the HTTPS redirect");
  });

  const response = await worker.fetch(
    new Request("http://tools.kiwi-ai.uk/icd10/?q=a%20b&lang=zh-Hant"),
  );

  assert.equal(response.status, 308);
  assert.equal(
    response.headers.get("location"),
    "https://tools.kiwi-ai.uk/icd10/?q=a%20b&lang=zh-Hant",
  );
  assert.equal(calls.length, 0);
  assertIcd10SecurityHeaders(response);
});

test("only allowlisted headers reach GitHub and ICD-10 HTML receives its compatible CSP", async () => {
  const calls = stubFetch(() =>
    new Response("<html>ok</html>", {
      status: 200,
      headers: {
        "Content-Type": "text/html; charset=utf-8",
        "Set-Cookie": "upstream=must-not-leak",
        "X-Upstream": "kept",
      },
    }),
  );

  const response = await worker.fetch(
    new Request("https://tools.kiwi-ai.uk/icd10/", {
      headers: {
        Accept: "text/html",
        Authorization: "Bearer secret",
        Cookie: "session=secret",
        "If-None-Match": '"etag"',
        Range: "bytes=0-99",
        "X-Internal-Secret": "secret",
      },
    }),
  );

  assert.equal(calls.length, 1);
  assert.equal(calls[0].input, "https://xyzkiwi.github.io/icd10-ed-quickref/");
  const sent = new Headers(calls[0].init.headers);
  assert.equal(sent.get("accept"), "text/html");
  assert.equal(sent.get("if-none-match"), '"etag"');
  assert.equal(sent.get("range"), "bytes=0-99");
  assert.equal(sent.get("authorization"), null);
  assert.equal(sent.get("cookie"), null);
  assert.equal(sent.get("x-internal-secret"), null);

  assert.equal(response.status, 200);
  assert.equal(response.headers.get("set-cookie"), null);
  assert.equal(response.headers.get("x-upstream"), "kept");
  assert.equal(response.headers.get("cache-control"), "public, max-age=300");
  assertIcd10SecurityHeaders(response);

  const csp = response.headers.get("content-security-policy");
  assert.match(csp, /default-src 'self'/);
  assert.match(csp, /https:\/\/static\.cloudflareinsights\.com/);
  assert.match(csp, /connect-src 'self' https:\/\/cloudflareinsights\.com/);
  assert.doesNotMatch(csp, /docs\.google\.com/);
  assert.match(csp, /frame-ancestors 'self'/);
});

test("other proxied apps receive generic headers without an untested CSP", async () => {
  stubFetch(() =>
    new Response("<html>calc</html>", {
      headers: { "Content-Type": "text/html; charset=utf-8" },
    }),
  );

  const response = await worker.fetch(new Request("https://tools.kiwi-ai.uk/calc/"));

  assert.equal(response.status, 200);
  assert.equal(response.headers.get("content-security-policy"), null);
  assertGenericSecurityHeaders(response);
});

test("upstream error status, status text, headers, and body are preserved", async () => {
  stubFetch(() =>
    new Response("origin unavailable", {
      status: 503,
      statusText: "Service Unavailable",
      headers: {
        "Content-Type": "text/plain; charset=utf-8",
        "Set-Cookie": "error-cookie=must-not-leak",
        "X-Upstream-Error": "yes",
      },
    }),
  );

  const response = await worker.fetch(
    new Request("https://tools.kiwi-ai.uk/icd10/unavailable"),
  );

  assert.equal(response.status, 503);
  assert.equal(response.statusText, "Service Unavailable");
  assert.equal(await response.text(), "origin unavailable");
  assert.equal(response.headers.get("x-upstream-error"), "yes");
  assert.equal(response.headers.get("set-cookie"), null);
  assert.equal(response.headers.get("cache-control"), "no-store");
  assertIcd10SecurityHeaders(response);
});

test("conditional 304 responses remain bodyless and retain validators", async () => {
  stubFetch(() =>
    new Response(null, {
      status: 304,
      statusText: "Not Modified",
      headers: { ETag: 'W/"current"' },
    }),
  );

  const response = await worker.fetch(
    new Request("https://tools.kiwi-ai.uk/icd10/", {
      headers: { "If-None-Match": 'W/"current"' },
    }),
  );

  assert.equal(response.status, 304);
  assert.equal(response.headers.get("etag"), 'W/"current"');
  assert.equal(await response.text(), "");
  assertIcd10SecurityHeaders(response);
});

test("HEAD is forwarded without a body and receives security headers", async () => {
  const calls = stubFetch((_input, init) => {
    assert.equal(init.method, "HEAD");
    return new Response(null, {
      status: 200,
      headers: {
        "Content-Type": "text/html; charset=utf-8",
        ETag: '"head-etag"',
      },
    });
  });

  const response = await worker.fetch(
    new Request("https://tools.kiwi-ai.uk/icd10/", { method: "HEAD" }),
  );

  assert.equal(calls.length, 1);
  assert.equal(response.status, 200);
  assert.equal(response.headers.get("etag"), '"head-etag"');
  assert.equal(await response.text(), "");
  assertIcd10SecurityHeaders(response);
});

test("an upstream fetch rejection becomes a safe non-cacheable 502", async () => {
  stubFetch(() => Promise.reject(new Error("network failure with sensitive details")));

  const response = await worker.fetch(
    new Request("https://tools.kiwi-ai.uk/icd10/?q=private"),
  );

  assert.equal(response.status, 502);
  assert.equal(response.headers.get("cache-control"), "no-store");
  assert.equal(response.headers.get("content-type"), "text/plain; charset=utf-8");
  assert.equal(await response.text(), "Bad Gateway");
  assertIcd10SecurityHeaders(response);
});

test("non-GET/HEAD methods are rejected locally", async () => {
  const calls = stubFetch(() => {
    throw new Error("upstream must not receive POST");
  });

  const response = await worker.fetch(
    new Request("https://tools.kiwi-ai.uk/icd10/", {
      method: "POST",
      body: "not forwarded",
    }),
  );

  assert.equal(response.status, 405);
  assert.equal(response.headers.get("allow"), "GET, HEAD");
  assert.equal(response.headers.get("cache-control"), "no-store");
  assert.equal(calls.length, 0);
  assertIcd10SecurityHeaders(response);
});

test("missing tool trailing slash keeps the query and receives security headers", async () => {
  const calls = stubFetch(() => {
    throw new Error("upstream must not be called for canonical redirect");
  });

  const response = await worker.fetch(
    new Request("https://tools.kiwi-ai.uk/icd10?source=bookmark"),
  );

  assert.equal(response.status, 301);
  assert.equal(
    response.headers.get("location"),
    "https://tools.kiwi-ai.uk/icd10/?source=bookmark",
  );
  assert.equal(calls.length, 0);
  assertIcd10SecurityHeaders(response);
});

test("download proxy keeps range support while stripping credentials", async () => {
  const calls = stubFetch(() =>
    new Response("partial zip", {
      status: 206,
      headers: {
        "Content-Type": "application/zip",
        "Content-Range": "bytes 0-10/100",
        "Set-Cookie": "github=must-not-leak",
      },
    }),
  );

  const response = await worker.fetch(
    new Request("https://tools.kiwi-ai.uk/medcloud.zip", {
      headers: {
        Authorization: "Bearer secret",
        Cookie: "session=secret",
        Range: "bytes=0-10",
      },
    }),
  );

  assert.equal(response.status, 206);
  assert.equal(
    calls[0].input,
    "https://github.com/xyzKIWI/CloudMedicationHelper/releases/latest/download/CloudMedicationHelper.zip",
  );
  const sent = new Headers(calls[0].init.headers);
  assert.equal(sent.get("range"), "bytes=0-10");
  assert.equal(sent.get("authorization"), null);
  assert.equal(sent.get("cookie"), null);
  assert.equal(response.headers.get("content-disposition"), 'attachment; filename="CloudMedicationHelper.zip"');
  assert.equal(response.headers.get("set-cookie"), null);
  assertGenericSecurityHeaders(response);
});
