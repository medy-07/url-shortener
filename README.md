# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

## Load testing

`load/redirect.js` is a [k6](https://k6.io) load test for the redirect
endpoint. Its `setup()` creates 100 short URLs through `POST /api/urls`. Then
50 virtual users spend 30 seconds requesting random codes with redirects
disabled and check for a `302`. The run fails if p95 `http_req_duration` is
200 ms or more, or if `http_req_failed` reaches 1%.

Start the app, then run:

```sh
k6 run load/redirect.js
```

The target defaults to `http://localhost:3000`. To point it somewhere else,
set `BASE_URL`:

```sh
BASE_URL=https://staging.example.com k6 run load/redirect.js
```

Each run creates 100 new rows in the `urls` table of the target environment.

### Results

Take requests per second from `http_reqs` and p95 latency from
`http_req_duration` in the k6 summary.

## Load testing

Run: `k6 run load/redirect.js` (50 virtual users, 30 seconds). Each row is
the middle result of three runs.

| Date | Mode | Cache | Requests/sec | Median | p95 | Failures |
|---|---|---|---|---|---|---|
| 2026-11-28 | dev, 1 worker | off | 424.7 | 97.9 ms | 228 ms | 0% |
