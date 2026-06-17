#!/usr/bin/env zsh

SCRIPT_DIR=$(dirname "${0:A}")
BREWFILE="$SCRIPT_DIR/Brewfile"
BUNFILE="$SCRIPT_DIR/Bunfile"

print_status() {
	echo "🔄 $1"
}

print_success() {
	echo "✅ $1"
}

print_error() {
	echo "❌ $1"
}

check_command() {
	if ! command -v "$1" &>/dev/null; then
		print_error "$1 is not installed or not in PATH"
		return 1
	fi
}

dumpBrew() {
	print_status "Generating optimized Brewfile with preserved options..."

	if ! check_command "brew"; then
		return 1
	fi

	# Create temporary files
	local temp_brewfile=$(mktemp)
	local temp_full_dump=$(mktemp)
	local temp_leaves=$(mktemp)
	local temp_casks=$(mktemp)

	# Generate a full dump to preserve options
	brew bundle dump --force --no-vscode --file="$temp_full_dump" &>/dev/null

	# Get lists of what we actually want (manually installed packages)
	brew leaves >"$temp_leaves" 2>/dev/null
	brew list --cask --full-name >"$temp_casks" 2>/dev/null

	# Start with taps
	grep '^tap ' "$temp_full_dump" >"$temp_brewfile"

	# Add formulae that are in brew leaves (preserving their options)
	while IFS= read -r package; do
		grep "^brew \"$package\"" "$temp_full_dump" >>"$temp_brewfile"
	done <"$temp_leaves"

	# Add casks that are actually installed (preserving their options if any)
	while IFS= read -r package; do
		grep "^cask \"$package\"" "$temp_full_dump" >>"$temp_brewfile"
	done <"$temp_casks"

	# Get Mac App Store apps (without version numbers)
	if check_command "mas" && mas list &>/dev/null; then
		mas list | awk '{
			gsub(/\([^)]*\)/, "");
			name="";
			for(i=2; i<=NF; i++) name=name $i " ";
			gsub(/ +$/, "", name);
			print "mas \"" name "\", id: " $1
		}' >>"$temp_brewfile"
	fi

	# Move temp file to final location
	mv "$temp_brewfile" "$BREWFILE"

	# Cleanup
	rm -f "$temp_full_dump" "$temp_leaves" "$temp_casks"

	print_success "Brewfile updated with $(grep -c '^brew\|^cask\|^mas' "$BREWFILE") packages (options preserved)"
}

dumpBun() {
	print_status "Generating bun global packages list..."

	if ! check_command "bun"; then
		print_error "bun not found, skipping bun packages dump"
		return 0
	fi

	# Locate the global package.json (bun's global dir varies with
	# BUN_INSTALL_GLOBAL_DIR / XDG cache; probe known locations)
	local global_pkg=""
	local candidate
	for candidate in \
		"${BUN_INSTALL_GLOBAL_DIR:-}" \
		"$HOME/.cache/.bun/install/global" \
		"${BUN_INSTALL:-$HOME/.bun}/install/global"; do
		if [ -n "$candidate" ] && [ -f "$candidate/package.json" ]; then
			global_pkg="$candidate/package.json"
			break
		fi
	done

	if [ -z "$global_pkg" ]; then
		print_error "Could not locate bun global package.json"
		return 1
	fi

	# Dependency names straight from package.json — survives scoped
	# packages (@antfu/ni) that text-parsing `bun pm ls -g` would mangle
	bun -e "console.log(Object.keys(require('$global_pkg').dependencies || {}).sort().join('\n'))" >"$BUNFILE" 2>/dev/null

	if [ ! -s "$BUNFILE" ]; then
		print_error "Bun packages dump produced an empty file"
		return 1
	fi

	local package_count=$(wc -l <"$BUNFILE" | tr -d ' ')
	print_success "Bun packages list updated with $package_count packages"
	return 0
}

dumpMackup() {
	print_status "Syncing app configs to iCloud (mackup)..."

	if ! check_command "mackup"; then
		print_error "mackup not found, skipping backup"
		return 0
	fi

	# Ensure dotfiles mackup definitions are active before backup
	if [[ -f "$SCRIPT_DIR/mackup.cfg" ]]; then
		ln -sf "$SCRIPT_DIR/mackup.cfg" "$HOME/.mackup.cfg"
	fi
	if [[ -d "$SCRIPT_DIR/mackup" ]]; then
		mkdir -p "$HOME/.mackup"
		for _mackup_cfg in "$SCRIPT_DIR/mackup"/*.cfg(.N); do
			ln -sf "$_mackup_cfg" "$HOME/.mackup/${_mackup_cfg:t}"
		done
		unset _mackup_cfg
	fi

	if mackup backup --force &>/dev/null; then
		print_success "Mackup backup completed"
		return 0
	else
		print_error "Mackup backup failed"
		return 0
	fi
}

__macos_read_default() {
	local domain="$1" key="$2" fallback="${3:-}"
	local value
	value=$(defaults read "$domain" "$key" 2>/dev/null) || {
		print "$fallback"
		return 0
	}
	print "$value"
}

__macos_bool_default() {
	local domain="$1" key="$2" fallback="${3:-false}"
	local value
	value=$(defaults read "$domain" "$key" 2>/dev/null) || {
		print "$fallback"
		return 0
	}
	[[ "$value" == "1" || "$value" == "true" ]] && print "true" || print "false"
}

__macos_timezone() {
	local link tz
	link=$(readlink /etc/localtime 2>/dev/null) || return 1
	tz="${link#*/zoneinfo/}"
	[[ -n "$tz" && "$tz" != "$link" ]] || return 1
	print "$tz"
}

captureMacos() {
	print_status "Capturing macOS settings and app configs..."

	local install_dir="$SCRIPT_DIR"
	local defaults_file="$install_dir/macos.defaults"
	local dock_file="$install_dir/dock-apps.list"
	local login_file="$install_dir/login-items.list"
	local duti_file="$install_dir/duti.list"
	local copied=0

	# App configs → iCloud via dumpMackup() (Ghostty, Karabiner, …)

	# Numeric / bool defaults → macos.defaults
	local timezone key_repeat initial_repeat font_smoothing trackpad_natural
	local trackpad_scrolling trackpad_scaling scrollwheel_scaling dock_tilesize
	local dock_expose dock_launch dock_min bclm_limit screen_lock screen_lock_delay

	timezone=$(__macos_timezone || print "Europe/Madrid")
	key_repeat=$(__macos_read_default NSGlobalDomain KeyRepeat 90)
	initial_repeat=$(__macos_read_default NSGlobalDomain InitialKeyRepeat 25)
	font_smoothing=$(__macos_read_default NSGlobalDomain AppleFontSmoothing 2)
	trackpad_natural=$(__macos_bool_default NSGlobalDomain com.apple.swipescrolldirection true)
	trackpad_scrolling=$(__macos_read_default NSGlobalDomain com.apple.trackpad.scrolling 0.5882)
	trackpad_scaling=$(__macos_read_default NSGlobalDomain com.apple.trackpad.scaling 0.875)
	scrollwheel_scaling=$(__macos_read_default NSGlobalDomain com.apple.scrollwheel.scaling 0.75)
	dock_tilesize=$(__macos_read_default com.apple.dock tilesize 53)
	dock_expose=$(__macos_read_default com.apple.dock expose-animation-duration 0)
	dock_launch=$(__macos_bool_default com.apple.dock launchanim false)
	dock_min=$(defaults read com.apple.dock mineffect 2>/dev/null || print "suck")
	bclm_limit="80"
	if command -v bclm &>/dev/null; then
		bclm_limit=$(bclm read 2>/dev/null || print "80")
	fi
	screen_lock=$(defaults read com.apple.screensaver askForPassword 2>/dev/null || true)
	screen_lock_delay=$(defaults read com.apple.screensaver askForPasswordDelay 2>/dev/null || print "0")

	cat >"$defaults_file" <<EOF
# Generated by prepare-migration.sh — safe to commit; re-run capture to refresh
MACOS_TIMEZONE="${timezone}"
MACOS_KEY_REPEAT=${key_repeat}
MACOS_INITIAL_KEY_REPEAT=${initial_repeat}
MACOS_FONT_SMOOTHING=${font_smoothing}
MACOS_TRACKPAD_NATURAL_SCROLL=${trackpad_natural}
MACOS_TRACKPAD_SCROLLING=${trackpad_scrolling}
MACOS_TRACKPAD_SCALING=${trackpad_scaling}
MACOS_SCROLLWHEEL_SCALING=${scrollwheel_scaling}
MACOS_DOCK_TILESIZE=${dock_tilesize}
MACOS_DOCK_EXPOSE_ANIMATION=${dock_expose}
MACOS_DOCK_LAUNCH_ANIM=${dock_launch}
MACOS_DOCK_MIN_EFFECT="${dock_min}"
MACOS_BCLM_LIMIT=${bclm_limit}
EOF

	if [[ "${screen_lock}" == "1" ]]; then
		cat >>"$defaults_file" <<EOF
MACOS_SCREEN_LOCK=1
MACOS_SCREEN_LOCK_DELAY=${screen_lock_delay}
EOF
	fi

	# Dock apps
	if command -v dockutil &>/dev/null && dockutil -l &>/dev/null; then
		dockutil -l | sed '/^[[:space:]]*$/d' >"$dock_file"
	elif [[ -f "$dock_file" ]]; then
		: # keep existing list
	else
		print_error "dockutil unavailable and no dock-apps.list — keeping existing file"
	fi

	# Login items
	if osascript -e 'tell application "System Events" to get path of every login item' &>/dev/null; then
		osascript -e 'tell application "System Events" to get path of every login item' 2>/dev/null |
			tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed '/^$/d' >"$login_file"
	fi

	# duti associations for Neovim Terminal extensions
	if [[ -f "$duti_file" ]]; then
		: # keep curated list; Neovim bundle is intentional
	fi

	print_success "macOS capture completed ($copied app configs, defaults, dock, login items)"
	return 0
}

main() {
	echo "🚀 Preparing migration packages and configurations..."
	echo ""

	local success_count=0
	local total_tasks=4

	if dumpBrew; then
		((success_count++))
	fi

	if dumpBun; then
		((success_count++))
	fi

	if dumpMackup; then
		((success_count++))
	fi

	if captureMacos; then
		((success_count++))
	fi

	echo ""
	echo "📊 Migration preparation completed: $success_count/$total_tasks tasks successful"

	if [ $success_count -eq $total_tasks ]; then
		echo "🎉 All tasks completed successfully!"
		echo "📝 Don't forget to commit and push these changes:"
		echo "   git add ."
		echo '   git commit -m "Update packages for migration"'
		echo "   git push"
		return 0
	else
		echo "⚠️  Some tasks failed. Please check the output above."
		return 1
	fi
}

main "$@"
