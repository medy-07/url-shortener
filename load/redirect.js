// Load test for the redirect endpoint (GET /:code).
//
//   k6 run load/redirect.js
//   BASE_URL=https://staging.example.com k6 run load/redirect.js
//
// setup() creates 100 short URLs through the API; each virtual user then
// requests random codes with redirects disabled and expects a 302.

import http from "k6/http";
import { check, fail } from "k6";

const BASE_URL = (__ENV.BASE_URL || "http://localhost:3000").replace(/\/+$/, "");
const URL_COUNT = 100;

export const options = {
  vus: 50,
  duration: "30s",
  thresholds: {
    http_req_duration: ["p(95)<200"],
    http_req_failed: ["rate<0.01"],
  },
};

export function setup() {
  const codes = [];

  for (let i = 0; i < URL_COUNT; i++) {
    const res = http.post(
      `${BASE_URL}/api/urls`,
      JSON.stringify({ long_url: `https://example.com/load-test/${Date.now()}/${i}` }),
      { headers: { "Content-Type": "application/json" } },
    );

    if (res.status !== 201) {
      fail(`setup: POST /api/urls returned ${res.status}: ${res.body}`);
    }

    // short_url is "<base>/<code>"; the code is the last path segment.
    codes.push(res.json("short_url").split("/").pop());
  }

  return { codes };
}

export default function (data) {
  const code = data.codes[Math.floor(Math.random() * data.codes.length)];
  const res = http.get(`${BASE_URL}/${code}`, {
    redirects: 0,
    tags: { name: "GET /:code" },
  });

  check(res, {
    "status is 302": (r) => r.status === 302,
  });
}
