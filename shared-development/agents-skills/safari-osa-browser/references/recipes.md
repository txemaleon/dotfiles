# Safari OSA recipes

Use these patterns after selecting Safari according to `SKILL.md`. The bundled `scripts/safari_osa` wrapper is preferred because it passes data through arguments and JavaScript through stdin without source interpolation.

## Contents

- Targeting and profile continuity
- Native AppleScript
- DOM inspection and interaction
- Waiting and verification
- JXA
- Accessibility UI scripting
- Screenshots and native dialogs
- Error handling

## Targeting and profile continuity

Filter tabs by the known service name or domain before using an authenticated session:

```bash
SAFARI_OSA="${CODEX_HOME:-$HOME/.codex}/skills/safari-osa-browser/scripts/safari_osa"
"$SAFARI_OSA" find-tabs 'app.example.com'
```

Choose the existing tab/window whose URL and title match the target account. Because Safari does not expose profiles through OSA, open related work in that same window:

```bash
"$SAFARI_OSA" open 'https://app.example.com/account' 2
"$SAFARI_OSA" list-tabs
```

Re-run `find-tabs` after mutations; indices are positional, not durable IDs. Use `list-tabs` only when the target cannot otherwise be identified, and avoid logging unrelated private browsing context.

## Native AppleScript

Pass dynamic values through `argv`:

```bash
osascript - 'https://example.com/path?q=a&b=c' 1 <<'APPLESCRIPT'
on run argv
    set targetURL to item 1 of argv
    set wi to item 2 of argv as integer
    tell application "Safari"
        set newTab to make new tab at end of tabs of window wi with properties {URL:targetURL}
        set current tab of window wi to newTab
        activate
    end tell
end run
APPLESCRIPT
```

Read a targeted page:

```applescript
tell application "Safari"
    set pageTitle to name of tab 2 of window 1
    set pageURL to URL of tab 2 of window 1
    set pageText to text of tab 2 of window 1
    set pageHTML to source of tab 2 of window 1
end tell
```

Manage windows and tabs:

```applescript
tell application "Safari"
    set current tab of window 1 to tab 3 of window 1
    set bounds of window 1 to {80, 80, 1360, 960}
    set miniaturized of window 2 to true
    close tab 3 of window 1
end tell
```

Use these externally visible commands only when requested:

```applescript
tell application "Safari"
    add reading list item "https://example.com/article" with title "Example"
    search the web in current tab of window 1 for "query"
    show bookmarks
    -- email contents of current tab of window 1
    -- print document 1 with properties {copies:1} print dialog true
end tell
```

## DOM inspection and interaction

Use stdin for multiline JavaScript:

```bash
"$SAFARI_OSA" js 1 2 <<'JS'
JSON.stringify(
  [...document.querySelectorAll('a,button,input,select,textarea,[role="button"]')]
    .filter(el => {
      const r = el.getBoundingClientRect();
      return r.width > 0 && r.height > 0;
    })
    .slice(0, 200)
    .map((el, index) => ({
      index,
      tag: el.tagName.toLowerCase(),
      role: el.getAttribute('role'),
      name: el.getAttribute('aria-label') || el.innerText || el.value || '',
      id: el.id || null
    }))
)
JS
```

Click only after verifying an unambiguous selector:

```bash
"$SAFARI_OSA" js 1 2 <<'JS'
(() => {
  const candidates = [...document.querySelectorAll('button')]
    .filter(el => el.textContent.trim() === 'Continue');
  if (candidates.length !== 1) throw new Error(`Expected 1 Continue button, found ${candidates.length}`);
  candidates[0].click();
  return 'clicked';
})()
JS
```

Fill a framework-controlled input using the native setter and events:

```bash
"$SAFARI_OSA" js 1 2 <<'JS'
(() => {
  const input = document.querySelector('input[name="query"]');
  if (!input) throw new Error('query input not found');
  const setter = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value').set;
  setter.call(input, 'example');
  input.dispatchEvent(new InputEvent('input', {bubbles: true, inputType: 'insertText', data: 'example'}));
  input.dispatchEvent(new Event('change', {bubbles: true}));
  return input.value;
})()
JS
```

Do not inspect password values, cookies, authorization data, or session tokens. The only exception is the explicitly authorized, named-site CLI cookie-extraction case defined in the parent `SKILL.md`; then inspect only the minimum cookie data needed and never print it. Avoid broad page dumps when only a small element or field is needed.

## Waiting and verification

Wait for initial load:

```bash
"$SAFARI_OSA" wait-ready 1 2 30
```

For dynamic conditions, poll with bounded shell logic and re-query the current tab each time. Avoid long blind sleeps:

```bash
ready=false
last_error=''
for attempt in {1..20}; do
  if result=$(printf '%s' 'Boolean(document.querySelector("[data-ready=true]"))' | "$SAFARI_OSA" js 1 2 2>&1); then
    if [[ "$result" == true ]]; then
      ready=true
      break
    fi
  else
    last_error=$result
  fi
  sleep 0.5
done
if [[ "$ready" != true ]]; then
  printf 'Dynamic page condition was not reached. Last error: %s\n' "$last_error" >&2
  exit 1
fi
```

After action, verify at least one observable result:

- URL or title changed as expected.
- Target element appeared/disappeared.
- Field contains the intended non-secret value.
- Server-confirmed status is visible.
- Download exists at the expected path and has a plausible type/size.

## JXA

Use JXA when JavaScript data shaping is convenient:

```bash
osascript -l JavaScript <<'JXA'
const safari = Application('Safari');
const rows = safari.windows().flatMap((window, wi) =>
  window.tabs().map((tab, ti) => ({
    window: wi + 1,
    tab: ti + 1,
    title: tab.name(),
    url: tab.url()
  }))
);
JSON.stringify(rows);
JXA
```

Evaluate page JavaScript:

```javascript
const safari = Application('Safari');
const tab = safari.windows[0].tabs[0];
const title = safari.doJavaScript('document.title', {in: tab});
```

Prefer AppleScript when JXA's generated method names or object specifiers behave ambiguously.

## Accessibility UI scripting

Use UI scripting only after native OSA and page JavaScript are insufficient. First inspect the AX hierarchy rather than guessing coordinates:

```bash
osascript <<'APPLESCRIPT'
tell application "Safari" to activate
tell application "System Events"
    tell process "Safari"
        set frontmost to true
        return {name, role, description} of every UI element of toolbar 1 of window 1
    end tell
end tell
APPLESCRIPT
```

Click a known menu item by name, accounting for system language:

```applescript
tell application "System Events"
    tell process "Safari"
        click menu item "Downloads" of menu "Window" of menu bar 1
    end tell
end tell
```

Keyboard shortcuts are a fallback when the menu/control is stable:

```applescript
tell application "Safari" to activate
tell application "System Events" to keystroke "l" using command down
```

Never use `keystroke` for credentials. Do not automate approval of a security or privacy prompt. Prefer roles/names over coordinates and verify focus before typing.

## Screenshots and native dialogs

Safari has no OSA screenshot command. If Screen Recording permission is available, use the macOS capture utility after activating and targeting the correct window. Avoid capturing unrelated windows or private data.

File upload, download-location, print, save, permission, and authentication sheets are native UI. Use Accessibility inspection, choose only the user-authorized path/account/action, and pause when macOS requires user presence.

## Error handling

Common failures:

- `Not authorized to send Apple events`: grant Automation permission to the host process controlling Safari.
- `osascript is not allowed assistive access`: grant Accessibility permission before using `System Events`.
- Safari reports that JavaScript from Apple Events is disabled: ask the user to enable **Develop > Allow JavaScript from Apple Events**.
- `Invalid index`: re-run `list-tabs`; another action changed the positional indices.
- DOM selector not found: wait for dynamic rendering, inspect the current document, and check for an iframe or shadow root.
- Cross-origin iframe: page JavaScript cannot cross the origin boundary; use the frame's own tab/context if possible or minimal UI scripting.
- Correct site but logged out: verify that the chosen window belongs to the intended Safari profile. Do not ask for or export passwords; let the user complete sign-in if needed.
