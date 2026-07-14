// Browser / URL router — symlinked to ~/.finicky.js by installer.sh
// Set Finicky as default browser in System Settings.

const bundleId = (name) => ({ name, appType: "bundleId" });

const ARC = bundleId("company.thebrowser.Browser");
const SAFARI = bundleId("com.apple.Safari");

const fromApp = (...bundleIds) => (_url, { opener } = {}) =>
	opener && bundleIds.includes(opener.bundleId);

const stripTracking = (url) => {
	for (const key of [...url.searchParams.keys()]) {
		if (key.startsWith("utm_") || key === "fbclid" || key === "gclid") {
			url.searchParams.delete(key);
		}
	}
	return url;
};

const GOOGLE_AND_YOUTUBE_HOSTS = [
	"googleadservices.com",
	"googleapis.com",
	"googleusercontent.com",
	"gstatic.com",
	"youtu.be",
	"youtube.com",
	"youtube-nocookie.com",
	"ytimg.com",
];

const matchesDomain = (host, domain) => host === domain || host.endsWith(`.${domain}`);

const isGoogleOrYoutube = (url) => {
	const host = url.hostname.toLowerCase();
	return (
		/(^|\.)google\.[a-z.]+$/.test(host) ||
		GOOGLE_AND_YOUTUBE_HOSTS.some((domain) => matchesDomain(host, domain))
	);
};

const isGoogleMaps = (url) => {
	const host = url.hostname.toLowerCase();
	return (
		/(^|\.)google\.[a-z.]+$/.test(host) &&
		(url.pathname.startsWith("/maps") || host.startsWith("maps."))
	);
};

/** @type {import('/Applications/Finicky.app/Contents/Resources/finicky.d.ts').FinickyConfig} */
export default {
	defaultBrowser: SAFARI,
	options: {
		keepRunning: true,
		hideIcon: true,
		checkForUpdates: true,
		logRequests: false,
	},
	rewrite: [{ match: () => true, url: stripTracking }],
	handlers: [
		// Native app handlers
		{
			match: ["*.notion.so/*", "notion.so/*", "*.notion.site/*", "notion.site/*"],
			browser: bundleId("notion.id"),
		},
		{
			match: ["discord.com/*", "*.discord.com/*", "discord.gg/*"],
			browser: bundleId("com.hnc.Discord"),
		},
		{
			match: ["t.me/*", "telegram.me/*"],
			browser: bundleId("ru.keepcoder.Telegram"),
		},
		{
			match: "music.apple.com/*",
			browser: bundleId("com.apple.Music"),
		},

		// Source-app rules
		{
			match: fromApp("com.tinyspeck.slackmacgap"),
			browser: ARC,
		},
		{
			match: fromApp("com.sindresorhus.Hyperduck"),
			browser: ARC,
		},

		// Domain rules
		{
			match: [
				"zoom.us/*",
				"*.zoom.us/*",
				"zoom.com/*",
				"*.zoom.com/*",
				"zoomgov.com/*",
				"*.zoomgov.com/*",
				"zoomstatus.com/*",
				"*.zoomstatus.com/*",
				"zoomapp.cloud/*",
				"*.zoomapp.cloud/*",
			],
			browser: null,
		},
		{
			match: isGoogleMaps,
			browser: ARC,
		},
		{
			match: isGoogleOrYoutube,
			browser: ARC,
		},
		{
			match: ["bing.com/*", "*.bing.com/*"],
			browser: ARC,
		},
		{
			match: ["txemaleon.net/*", "*.txemaleon.net/*"],
			browser: ARC,
		},
		{
			match: ["shortcut.com/*", "*.shortcut.com/*"],
			browser: ARC,
		},
		{
			match: ["apple.com/*", "*.apple.com/*"],
			browser: SAFARI,
		},
		{
			match: ["twitter.com/*", "*.twitter.com/*", "x.com/*", "*.x.com/*"],
			browser: ARC,
		},
		{
			match: ["airtable.com/*", "*.airtable.com/*"],
			browser: ARC,
		},
	],
};
