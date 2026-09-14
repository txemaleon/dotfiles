#!/usr/bin/env node

import { execFile, spawnSync } from 'node:child_process';
import { readFile, stat } from 'node:fs/promises';
import { homedir } from 'node:os';
import { join } from 'node:path';
import { promisify } from 'node:util';

const execFileAsync = promisify(execFile);
const HOST = (process.env.UMAMI_HOST_URL ?? 'https://click.txemaleon.net').replace(/\/$/, '');
const USERNAME = process.env.UMAMI_USERNAME ?? 'Agent';
const KEYCHAIN_SERVICE = process.env.UMAMI_KEYCHAIN_SERVICE ?? 'click.txemaleon.net';
// The stored macOS credential label is independent of the renamed Umami login.
const KEYCHAIN_ACCOUNT = process.env.UMAMI_KEYCHAIN_ACCOUNT ?? process.env.UMAMI_USERNAME ?? 'claude';
const TEAM_NAME = process.env.UMAMI_TEAM_NAME ?? 'Txemaleon Analytics';
const CREDENTIAL_FILE =
  process.env.UMAMI_CREDENTIAL_FILE ?? join(homedir(), '.config/umami-analytics/password.cred');
const CREDENTIAL_NAME = process.env.UMAMI_CREDENTIAL_NAME ?? 'password';
const SAFE_BREAKDOWNS = new Set([
  'path',
  'entry',
  'exit',
  'title',
  'referrer',
  'channel',
  'domain',
  'country',
  'region',
  'browser',
  'os',
  'device',
  'language',
  'event',
  'hostname',
  'utmSource',
  'utmMedium',
  'utmCampaign',
]);
const UTM_BREAKDOWN_FIELDS = new Map([
  ['utmSource', 'utm_source'],
  ['utmMedium', 'utm_medium'],
  ['utmCampaign', 'utm_campaign'],
]);

let token;
let team;
let websites;

function asArray(value) {
  if (Array.isArray(value)) return value;
  if (Array.isArray(value?.data)) return value.data;
  return [];
}

async function getPassword() {
  if (process.env.UMAMI_PASSWORD) return process.env.UMAMI_PASSWORD;

  if (process.platform === 'darwin') {
    const { stdout } = await execFileAsync('security', [
      'find-generic-password',
      '-a',
      KEYCHAIN_ACCOUNT,
      '-s',
      KEYCHAIN_SERVICE,
      '-w',
    ]);
    return stdout.trim();
  }

  const metadata = await stat(CREDENTIAL_FILE);
  if (metadata.uid !== process.getuid()) throw new Error('Umami credential has the wrong owner');
  if ((metadata.mode & 0o077) !== 0) throw new Error('Umami credential permissions must be 0600');
  const decrypted = spawnSync(
    'systemd-creds',
    ['decrypt', '--user', `--name=${CREDENTIAL_NAME}`, '-', '-'],
    {
      input: await readFile(CREDENTIAL_FILE),
      encoding: 'utf8',
      timeout: 10_000,
      maxBuffer: 1024 * 1024,
    },
  );
  if (decrypted.error) throw decrypted.error;
  if (decrypted.status !== 0) {
    throw new Error(`Unable to decrypt Umami credential: ${decrypted.stderr.trim()}`);
  }
  return decrypted.stdout.trim();
}

async function login() {
  const response = await fetch(`${HOST}/api/auth/login`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ username: USERNAME, password: await getPassword() }),
  });
  if (!response.ok) throw new Error(`Umami login failed (${response.status})`);
  const data = await response.json();
  token = data.token;
  return data.user;
}

async function request(path, options = {}, retry = true) {
  if (!token) await login();
  const response = await fetch(`${HOST}${path}`, {
    method: options.method ?? 'GET',
    headers: {
      authorization: `Bearer ${token}`,
      ...(options.body === undefined ? {} : { 'content-type': 'application/json' }),
    },
    ...(options.body === undefined ? {} : { body: JSON.stringify(options.body) }),
  });
  if (response.status === 401 && retry) {
    token = undefined;
    return request(path, options, false);
  }
  if (!response.ok) throw new Error(`Umami ${path} failed (${response.status})`);
  return response.json();
}

async function getTeam() {
  if (team) return team;
  team = asArray(await request('/api/teams')).find(item => item.name === TEAM_NAME);
  if (!team) throw new Error(`Umami team not found: ${TEAM_NAME}`);
  return team;
}

async function listWebsites(refresh = false) {
  if (websites && !refresh) return websites;
  const selectedTeam = await getTeam();
  websites = asArray(await request(`/api/teams/${selectedTeam.id}/websites`));
  return websites;
}

function publicWebsite(website) {
  return { id: website.id, name: website.name, domain: website.domain };
}

async function resolveWebsite(query) {
  const normalized = query.trim().toLowerCase();
  const all = await listWebsites();
  const exact = all.filter(website =>
    [website.id, website.name, website.domain]
      .filter(Boolean)
      .some(value => String(value).toLowerCase() === normalized),
  );
  if (exact.length === 1) return exact[0];
  const partial = all.filter(website =>
    [website.name, website.domain]
      .filter(Boolean)
      .some(value => String(value).toLowerCase().includes(normalized)),
  );
  if (partial.length === 1) return partial[0];
  if (partial.length > 1) {
    throw new Error(`Ambiguous website: ${query}. Matches: ${partial.map(item => item.name).join(', ')}`);
  }
  throw new Error(`Unknown website: ${query}`);
}

function parseArgs(argv) {
  const [command = 'help', ...rest] = argv;
  const positional = [];
  const flags = {};
  for (let index = 0; index < rest.length; index += 1) {
    const value = rest[index];
    if (!value.startsWith('--')) {
      positional.push(value);
      continue;
    }
    const name = value.slice(2);
    const next = rest[index + 1];
    if (!next || next.startsWith('--')) flags[name] = true;
    else {
      flags[name] = next;
      index += 1;
    }
  }
  return { command, positional, flags };
}

function integerFlag(flags, name, fallback, minimum, maximum) {
  const value = flags[name] === undefined ? fallback : Number(flags[name]);
  if (!Number.isInteger(value) || value < minimum || value > maximum) {
    throw new Error(`--${name} must be an integer between ${minimum} and ${maximum}`);
  }
  return value;
}

function range(days) {
  const endAt = Date.now();
  return { startAt: endAt - days * 86_400_000, endAt };
}

function queryString(values) {
  return new URLSearchParams(Object.fromEntries(Object.entries(values).map(([key, value]) => [key, String(value)])));
}

async function stats(website, days) {
  return request(`/api/websites/${website.id}/stats?${queryString(range(days))}`);
}

async function timeseries(website, days, unit) {
  return request(
    `/api/websites/${website.id}/pageviews?${queryString({ ...range(days), unit, timezone: 'Europe/Madrid' })}`,
  );
}

function normalizeUtmMetrics(rows, limit) {
  return asArray(rows)
    .filter(row => typeof row?.utm === 'string' && Number.isFinite(row?.views))
    .slice(0, limit)
    .map(row => ({ x: row.utm, y: row.views }));
}

async function utmBreakdown(website, days, type, limit) {
  const field = UTM_BREAKDOWN_FIELDS.get(type);
  if (!field) throw new Error(`Unsupported UTM breakdown type: ${type}`);
  const { startAt, endAt } = range(days);
  const report = await request('/api/reports/utm', {
    method: 'POST',
    body: {
      websiteId: website.id,
      type: 'utm',
      filters: {},
      parameters: {
        startDate: new Date(startAt).toISOString(),
        endDate: new Date(endAt).toISOString(),
      },
    },
  });
  return normalizeUtmMetrics(report?.[field], limit);
}

async function breakdown(website, days, type, limit) {
  if (!SAFE_BREAKDOWNS.has(type)) throw new Error(`Unsupported breakdown type: ${type}`);
  if (UTM_BREAKDOWN_FIELDS.has(type)) return utmBreakdown(website, days, type, limit);
  return request(
    `/api/websites/${website.id}/metrics?${queryString({ ...range(days), type, limit })}`,
  );
}

async function active(website) {
  return request(`/api/websites/${website.id}/active`);
}

function requireWebsite(positional) {
  if (!positional[0]) throw new Error('A website name, domain, or ID is required');
  return positional[0];
}

async function run() {
  const { command, positional, flags } = parseArgs(process.argv.slice(2));
  if (command === 'help') {
    return {
      usage: 'umami.mjs <sites|overview|timeseries|breakdown|realtime|report|self-test> [website] [--days N] [--unit day] [--type path] [--limit N]',
    };
  }
  if (command === 'sites') {
    return { websites: (await listWebsites(true)).map(publicWebsite) };
  }
  if (command === 'self-test') {
    const user = await login();
    const available = await listWebsites(true);
    if (user.role !== 'view-only') throw new Error(`Expected view-only role, received ${user.role}`);
    if (available.length === 0) throw new Error('No Umami websites are available');
    const sample = available.find(item => item.domain === 'airtabletocalendar.com') ?? available[0];
    const fixture = normalizeUtmMetrics([{ utm: 'self-test', views: 1 }], 1);
    if (fixture[0]?.x !== 'self-test' || fixture[0]?.y !== 1) {
      throw new Error('UTM metric normalization failed');
    }
    const [summary, ...breakdowns] = await Promise.all([
      stats(sample, 1),
      ...['path', 'referrer', 'event', ...UTM_BREAKDOWN_FIELDS.keys()].map(type =>
        breakdown(sample, 1, type, 1),
      ),
    ]);
    if (!summary || breakdowns.some(value => !Array.isArray(value))) {
      throw new Error('Umami analytics access check failed');
    }
    return {
      ok: true,
      role: user.role,
      websites: available.length,
      statsAccess: true,
      metricsAccess: ['path', 'referrer', 'event'],
      utmAccess: [...UTM_BREAKDOWN_FIELDS.keys()],
    };
  }

  const website = await resolveWebsite(requireWebsite(positional));
  if (command === 'realtime') {
    return { website: publicWebsite(website), active: await active(website) };
  }

  const days = integerFlag(flags, 'days', command === 'overview' || command === 'report' ? 7 : 30, 1, 730);
  if (command === 'overview') {
    return { website: publicWebsite(website), days, stats: await stats(website, days) };
  }
  if (command === 'timeseries') {
    const unit = flags.unit ?? 'day';
    if (!['hour', 'day', 'month'].includes(unit)) throw new Error('--unit must be hour, day, or month');
    return { website: publicWebsite(website), days, unit, series: await timeseries(website, days, unit) };
  }
  if (command === 'breakdown') {
    const type = flags.type ?? 'path';
    const limit = integerFlag(flags, 'limit', 20, 1, 100);
    return { website: publicWebsite(website), days, type, metrics: await breakdown(website, days, type, limit) };
  }
  if (command === 'report') {
    const limit = integerFlag(flags, 'limit', 20, 1, 100);
    const unit = days <= 2 ? 'hour' : days <= 180 ? 'day' : 'month';
    const [summary, series, pages, referrers, events, realtime] = await Promise.all([
      stats(website, days),
      timeseries(website, days, unit),
      breakdown(website, days, 'path', limit),
      breakdown(website, days, 'referrer', limit),
      breakdown(website, days, 'event', limit),
      active(website),
    ]);
    return {
      website: publicWebsite(website),
      days,
      generatedAt: new Date().toISOString(),
      stats: summary,
      series: { unit, ...series },
      topPages: pages,
      topReferrers: referrers,
      events,
      active: realtime,
    };
  }
  throw new Error(`Unknown command: ${command}`);
}

try {
  console.log(JSON.stringify(await run(), null, 2));
} catch (error) {
  console.error(JSON.stringify({ error: error instanceof Error ? error.message : String(error) }));
  process.exitCode = 1;
}
