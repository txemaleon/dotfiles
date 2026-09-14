# Google Search Console and Bing CLI

Use the globally installed, version-pinned `search-console-mcp@2.1.3` for
first-party Google Search Console and Bing Webmaster Tools evidence. The same
host identity covers the portfolio; project isolation is enforced by always
passing the current project's exact property identifier.

## Safety contract

- Automated audits are read-only. Do not call `sites_manage`,
  `accounts_manage`, `sitemaps_submit`, `sitemaps_delete`, `indexing_submit` or
  any other mutating operation.
- Do not change accounts, authorization or selected sites during an audit.
- Do not run credential bootstrap helpers from an audit. If authorization is
  missing or expired, report it for manual maintenance.
- Never print tokens, API keys, account emails, account aliases or unrelated
  properties/query data.
- Work only on the current project unless the user explicitly requests a
  portfolio-wide report.
- Use `--format=json` so agents receive deterministic structured output.
- In `search-console-mcp@2.1.3`, do not use `analytics_query` for Bing: its
  unified handler ignores the requested dates and row limit and can return an
  unbounded historical payload. Use the bounded helper below for Bing query
  and position rows; use `analytics_compare` for Bing period totals.
- Treat missing credentials, permissions or properties as unavailable
  evidence. Do not replace Search Console data with analytics estimates.

## Resolve the property before every project-scoped run

Google may expose a URL-prefix property such as `https://example.com/` or a
domain property such as `sc-domain:example.com`; Bing normally exposes a URL.
Never guess which form is authorized.

```bash
search-console-mcp diagnostics
/home/txemaleon/agents/personal-agent/automation/search-console/list-project-properties.mjs \
  --domain="example.com" \
  --engine=all
```

The bounded property lookup deliberately hides unrelated properties and
Bing's auxiliary verification codes. Match only the canonical public domain of
the current repository, retain the exact returned value, and pass that value
as `--siteUrl`. If no unambiguous match exists, report `NO VERIFICABLE` or
`UNAVAILABLE` with the missing property/permission instead of querying a
different site. Do not call raw `sites_list` in a project-scoped audit.

## Portfolio domain map

| Repository | Public domain |
|---|---|
| `/home/txemaleon/code/asincrono.com` | `asincrono.com` |
| `/home/txemaleon/code/blog` | `txemaleon.com` |
| `/home/txemaleon/code/pppodcasts.com` | `pppodcasts.com` |
| `/home/txemaleon/code/recibirlicitaciones.com` | `recibirlicitaciones.com` |
| `/home/txemaleon/code/notioncalendars` | `notiontocalendar.com` |
| `/home/txemaleon/code/viajarsindestino` | `viajarsindestino.com` |
| `/home/txemaleon/code/airtabletocalendar` | `airtabletocalendar.com` |
| `/home/txemaleon/code/notiontomaps` | `notiontomaps.com` |
| `/home/txemaleon/code/renewable-grid-intelligence-atlas` | `renewable-grid-intelligence-atlas.vercel.app` |
| `/home/txemaleon/code/fyinbox` | `fyinbox.com` |

The map identifies the expected domain, not the API property syntax. The
authorized `sites_list` response remains authoritative.

## Read-only recipes

Replace the placeholders with ISO dates and the exact property identifier.
Array options use comma-separated values.

```bash
# Search performance by date, query and page.
search-console-mcp run analytics_query \
  --siteUrl="{exact_property_id}" \
  --startDate="YYYY-MM-DD" \
  --endDate="YYYY-MM-DD" \
  --dimensions="date,query,page" \
  --rowLimit=1000 \
  --engine=google \
  --format=json

# Explicit period comparison; run per engine when property IDs differ.
search-console-mcp run analytics_compare \
  --siteUrl="{exact_property_id}" \
  --startDate="YYYY-MM-DD" \
  --endDate="YYYY-MM-DD" \
  --compareStartDate="YYYY-MM-DD" \
  --compareEndDate="YYYY-MM-DD" \
  --engine=bing \
  --format=json

# Bounded Bing query/position rows. This applies the requested date window and
# limit before returning JSON.
/home/txemaleon/agents/personal-agent/automation/search-console/read-bing-performance.mjs \
  --siteUrl="{exact_bing_property_url}" \
  --startDate="YYYY-MM-DD" \
  --endDate="YYYY-MM-DD" \
  --groupBy=query \
  --rowLimit=100

# Indexing, sitemap and overall health evidence.
search-console-mcp run inspection_inspect \
  --siteUrl="{exact_property_id}" \
  --urls="https://example.com/,https://example.com/important-page" \
  --engine=google \
  --format=json
search-console-mcp run sitemaps_list \
  --siteUrl="{exact_property_id}" \
  --engine=google \
  --format=json
search-console-mcp run site_health_check \
  --siteUrl="{exact_property_id}" \
  --level=summary \
  --engine=google \
  --format=json
```

Use `compare_engines` only when both engines accept the same property URL;
otherwise query them separately and join the aggregate results in the report.

Google Search Console data normally has a processing delay, and Bing query
statistics can update less frequently. State the actual complete date window
returned by each source and do not describe partial data as a full week or
month.

`genai_query_insights` is heuristic classification of ordinary Google/Bing
queries. Neither engine exposes official generative-answer citation data
through these APIs. It may support an explicitly labelled inference, but never
an authoritative GEO visibility or citation claim.
