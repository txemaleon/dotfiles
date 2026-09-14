# Safari OSA capabilities

This inventory is based on Safari 18.6's installed scripting definition at `/Applications/Safari.app/Contents/Resources/Safari.sdef` plus `/System/Library/ScriptingDefinitions/CocoaStandard.sdef`. Re-check those files after macOS or Safari upgrades when exact support matters.

## Contents

- Native public Safari dictionary
- Standard Suite inherited by Safari
- Hidden and private dictionary entries
- Page JavaScript capabilities
- System Events UI-scripting capabilities
- OSA languages and invocation surfaces
- Permissions and security boundaries
- Known gaps and non-capabilities

## Native public Safari dictionary

### Application

Read these application properties:

- `name` (text, read-only)
- `frontmost` (boolean, read-only)
- `version` (text, read-only)
- `documents` (ordered Safari documents, one active-tab document per window)
- `windows` (ordered front to back)

The application responds natively to `open`, `print`, and `quit`. Generic object commands from the Standard Suite can also create and manage supported Safari objects.

### Window

Safari extends the standard `window` class with:

- `current tab` (read/write tab reference)
- `tabs` (ordered left to right)

Inherited window properties:

- `name` (read-only title)
- `id` (read-only integer identifier)
- `index` (read/write front-to-back position)
- `bounds` (read/write rectangle `{left, top, right, bottom}`)
- `closeable` (read-only)
- `miniaturizable` (read-only)
- `miniaturized` (read/write)
- `resizable` (read-only)
- `visible` (read/write)
- `zoomable` (read-only)
- `zoomed` (read/write)
- `document` (read-only active-tab document)

Windows respond to `close`, `print`, and `save` through the Standard Suite. Some generic command/object combinations are declared by Cocoa but are not useful for web content; verify actual results.

### Document

A Safari document represents the active tab in a window. Safari adds:

- `source` (HTML source, read-only)
- `URL` (text, read/write)
- `text` (rendered page text snapshot, read-only; changing the returned text does not change the page)

Inherited properties are `name` (read-only), `modified` (read-only), and `file` (read-only, normally absent for web pages). A document responds to `close`, `print`, `save`, `do JavaScript`, `email contents`, and `search the web`.

### Tab

Tab properties:

- `source` (HTML source, read-only)
- `URL` (text, read/write)
- `index` (read-only, left-to-right order)
- `text` (rendered page text snapshot, read-only)
- `visible` (read-only; true for the selected tab)
- `name` (read-only title)

A tab responds to `do JavaScript`, `email contents`, `close`, and `search the web`.

### Safari-specific commands

- `add reading list item URL [with title TITLE] [and preview text TEXT]`: add a Reading List item.
- `do JavaScript CODE [in TAB_OR_DOCUMENT]`: evaluate JavaScript in a page and return an AppleScript-compatible result. Requires Safari's **Allow JavaScript from Apple Events** setting.
- `email contents of TAB_OR_DOCUMENT`: open an email-composition workflow containing the page. This is externally visible; use only when requested.
- `search the web in TAB_OR_DOCUMENT for QUERY`: use Safari's configured search provider in the target.
- `show bookmarks`: open Safari's bookmarks view.

## Standard Suite inherited by Safari

Public commands declared by Cocoa Standard Terminology:

- `open FILE_OR_FILES`
- `close OBJECT [saving yes|no|ask] [saving in FILE]`
- `save OBJECT [in FILE] [as FORMAT]`
- `print FILES_OR_OBJECT [with properties PRINT_SETTINGS] [print dialog BOOLEAN]`
- `quit [saving yes|no|ask]`
- `count OBJECT [each CLASS]`
- `delete OBJECT`
- `duplicate OBJECT [to LOCATION] [with properties RECORD]`
- `exists OBJECT`
- `make new CLASS [at LOCATION] [with data DATA] [with properties RECORD]`
- `move OBJECT to LOCATION`

Print settings include copies, collating, starting/ending page, pages across/down, requested print time, error handling, fax number, and target printer. Safari declares these common commands, but web-page behavior varies; test before relying on file-saving, duplication, deletion, movement, or advanced print settings.

Practical, proven patterns include `make new document with properties {URL:...}`, `make new tab at end of tabs of window N with properties {URL:...}`, changing a tab's `URL`, selecting `current tab`, changing window bounds/state, and closing a tab/window.

## Hidden and private dictionary entries

Safari 18.6 declares these hidden entries:

- `show extensions preferences EXTENSION_IDENTIFIER` with a Safari access group
- `dispatch message to extension DICTIONARY` with a Safari access group
- `sync all plist to disk` with a private Safari entitlement
- `show privacy report`
- `show credit card settings`
- internal `sourceProvider` and `contentsProvider` classes
- hidden tab `pid` for the WebContent process

Record them for completeness, but do not treat hidden or entitlement-gated entries as supported automation APIs. Do not invoke credit-card settings, extension messaging, private synchronization, or hidden process hooks unless the user explicitly requests a legitimate diagnostic and the command is demonstrably available. Prefer public APIs and UI scripting.

## Page JavaScript capabilities

`do JavaScript` runs in the selected page's authenticated web context. It can:

- Inspect `document`, DOM nodes, attributes, accessible names, computed styles, geometry, forms, links, tables, and rendered state.
- Query elements with CSS selectors and XPath.
- Focus, click, scroll, select, and edit DOM-backed controls; dispatch keyboard/input/change/pointer events when a framework requires them.
- Read or change the page URL, history, hash, and in-page navigation state.
- Observe mutations, wait on conditions, and inspect `document.readyState`.
- Execute same-origin `fetch`/XHR with the page's session subject to CORS, CSP, browser policy, and the task's authorization.
- Read non-secret page data from `localStorage`, `sessionStorage`, IndexedDB, and JavaScript variables when legitimately needed. Never extract tokens, credentials, or unrelated personal data. Cookie extraction is allowed only under the explicit, named-site CLI exception in the parent `SKILL.md`.
- Trigger DOM downloads, print UI, or file inputs, though native download prompts and file choosers may require UI scripting.
- Return strings, numbers, booleans, lists, and simple records that OSA can bridge. Use `JSON.stringify(...)` for complex results.

Important limits:

- It cannot read `HttpOnly` cookies or bypass same-origin isolation, CORS, sandboxed/cross-origin frames, browser permissions, CAPTCHA, passkeys, biometrics, or user-confirmation requirements.
- It cannot directly automate Safari chrome, native sheets, permission prompts, the Downloads popover, Keychain/autofill UI, or file chooser UI.
- Content scripts can become stale after navigation or dynamic rerenders. Re-query elements before each action and verify afterward.
- Some sites ignore `element.click()` or direct `.value=` changes. Use native property setters plus `input`/`change` events, or fall back to Accessibility UI scripting.
- JavaScript is powerful enough to expose account data. Keep reads narrowly scoped and never return session secrets.

## System Events UI-scripting capabilities

With Accessibility permission, `System Events` can inspect and operate Safari's accessibility tree. It can generally:

- Activate Safari and address a specific process/window.
- Read or operate menu bars, menu items, buttons, toolbars, text fields, groups, sheets, popovers, tables, outlines, checkboxes, radio buttons, and other exposed AX elements.
- Use keyboard shortcuts and `keystroke`/`key code` for browser chrome.
- Control the address/search field, reload/back/forward UI, tabs and tab overview, downloads UI, Reader controls, extension buttons, settings, native permission prompts, and print/save/open/file-chooser dialogs when those controls are exposed.
- Reach profile- or private-window commands through menus when the public Safari dictionary cannot, subject to localization and current UI layout.

UI scripting is an unstable fallback, not a semantic browser protocol. Inspect the live AX hierarchy first; prefer roles, descriptions, titles, and menu names over screen coordinates; target a specific window; account for localization; and verify the resulting page state. Never approve security/privacy prompts or choose an account on the user's behalf when the choice is consequential or ambiguous.

Screen capture through `screencapture` or other macOS facilities can complement UI scripting but can require Screen Recording permission. The Safari dictionary itself has no screenshot command.

## OSA languages and invocation surfaces

- AppleScript via `osascript`, Script Editor, Shortcuts, Automator, shell scripts, or compiled `.scpt` files is the best documented and most reliable surface for Safari's dictionary.
- JavaScript for Automation (JXA) via `osascript -l JavaScript` exposes the same application dictionary with JavaScript syntax, for example `Application('Safari').windows()` and `safari.doJavaScript(code, {in: tab})`. Dictionary bridging can be less obvious than AppleScript; prefer AppleScript for fragile commands and JXA for data shaping.
- Objective-C bridges (`use framework` in AppleScriptObjC or `ObjC.import` in JXA) can call macOS frameworks, but they do not expand Safari's public browser automation API and should not be used to bypass privacy controls.
- The `open` command and `open location`/Launch Services can send URLs to Safari, but they do not guarantee the correct Safari profile. Open a tab in a known existing window when session context matters.

## Permissions and security boundaries

- **Automation**: the process running `osascript` may need permission to control Safari and System Events under System Settings > Privacy & Security > Automation.
- **Accessibility**: required for `System Events` UI scripting under Privacy & Security > Accessibility.
- **Screen Recording**: required for reliable screenshots of other apps/windows.
- **Safari setting**: Develop > Allow JavaScript from Apple Events is required for `do JavaScript`.
- **User presence**: passkeys, Touch ID, Apple Pay/payment confirmation, CAPTCHA, Keychain unlock, security keys, and some permission prompts intentionally require the user.

Use the least privileged layer that can complete the task. Native dictionary reads need fewer permissions and are more stable than UI scripting.

## Known gaps and non-capabilities

Safari's public OSA dictionary does not expose APIs to:

- Enumerate or select Safari profiles, private-browsing state, tab groups, pinned-tab state, extensions, or website data stores.
- Read or write bookmarks/history as structured collections; only `show bookmarks` and `add reading list item` are public Safari-specific commands.
- Inspect network requests, console logs, performance traces, Web Inspector, service workers, or downloads as structured automation objects.
- Take screenshots, record video, generate PDFs without print UI, emulate devices, intercept traffic, mock responses, or provide Playwright-style stable element references.
- Directly manage cookies, passwords, passkeys, Keychain items, autofill records, Apple Pay, or Safari settings.
- Reliably automate browser chrome without Accessibility UI scripting.

For anonymous tasks needing those browser-testing capabilities, use `agent-browser`. For account-bound tasks, combine Safari's page context with minimal UI scripting and user participation rather than exporting the session elsewhere.
