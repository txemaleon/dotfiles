// Browser / URL router — symlinked to ~/.finicky.js by installer.sh
// Set Finicky as default browser in System Settings.

const ARC = "company.thebrowser.Browser";
const SAFARI = "com.apple.Safari";

const fromApp = (...bundleIds) => ({ opener }) =>
	opener && bundleIds.includes(opener.bundleId);

const stripTracking = ({ url }) => {
	for (const key of [...url.searchParams.keys()]) {
		if (key.startsWith("utm_") || key === "fbclid" || key === "gclid") {
			url.searchParams.delete(key);
		}
	}
	return url;
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
			match: ["zoom.us/j/*", "*.zoom.us/j/*"],
			browser: "us.zoom.xos",
		},
		{
			match: ["*.notion.so/*", "notion.so/*", "*.notion.site/*", "notion.site/*"],
			browser: "notion.id",
		},
		{
			match: ["discord.com/*", "*.discord.com/*", "discord.gg/*"],
			browser: "com.hnc.Discord",
		},
		{
			match: ["t.me/*", "telegram.me/*"],
			browser: "ru.keepcoder.Telegram",
		},
		{
			match: "music.apple.com/*",
			browser: "com.apple.Music",
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
			match: ["youtube.com/*", "*.youtube.com/*"],
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
			match: ["meet.google.com/*"],
			browser: ARC,
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
