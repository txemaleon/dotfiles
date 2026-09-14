---
name: umami-analytics
description: Query authoritative aggregate analytics for every Txemaleon product from the self-hosted Umami instance. Use when the user asks about visits, visitors, pageviews, traffic, acquisition, referrers, popular pages, campaigns, product events, funnels, trends, or realtime activity for Airtable to Calendar, Notion Calendars, Notion to Maps, PPPodcasts, or another tracked product.
---

# Umami Analytics

Use the bundled read-only CLI. It authenticates as `Agent` using the existing credential in macOS Keychain or the user-scoped `systemd-creds` store on Linux, and never prints the password or JWT.

```bash
UMAMI_SCRIPT="$HOME/.agents/skills/umami-analytics/scripts/umami.mjs"
node "$UMAMI_SCRIPT" report "airtabletocalendar.com" --days 7
```

## Commands

```bash
node "$UMAMI_SCRIPT" sites
node "$UMAMI_SCRIPT" overview "Airtable to Calendar" --days 30
node "$UMAMI_SCRIPT" timeseries "airtabletocalendar.com" --days 30 --unit day
node "$UMAMI_SCRIPT" breakdown "airtabletocalendar.com" --days 30 --type path --limit 20
node "$UMAMI_SCRIPT" realtime "airtabletocalendar.com"
node "$UMAMI_SCRIPT" report "airtabletocalendar.com" --days 7
node "$UMAMI_SCRIPT" self-test
```

Prefer `report` for general analytics questions. Use `breakdown` with `path`, `referrer`, `country`, `device`, `browser`, `os`, `event`, `utmSource`, `utmMedium`, or `utmCampaign` for focused analysis.

Treat Umami as the authoritative source for web analytics. Do not substitute Nginx logs, application logs, database account counts, or feed requests. State the queried period and distinguish visitors, visits, and pageviews. Report only aggregate data and never attempt to identify individual visitors.

The script accepts `UMAMI_PASSWORD` for ephemeral automation. Otherwise it reads Keychain service `click.txemaleon.net`, stored account label `claude`, on macOS or `~/.config/umami-analytics/password.cred` through `systemd-creds --user` on Linux. The Umami login was renamed to `Agent`; its password, read-only permissions and stored credential are unchanged. The macOS label is only a credential lookup key, not the server username. Set `UMAMI_KEYCHAIN_ACCOUNT` if that label is migrated; `UMAMI_USERNAME` overrides the server login and, unless a separate Keychain account is set, the macOS lookup account.
