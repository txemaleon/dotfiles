#!/usr/bin/env zsh

# Cleanup script: removes packages not defined in Brewfile/Bunfile
# Usage: ./cleanup.sh [--dry-run]

set -e

SCRIPT_DIR="${0:A:h}"
BREWFILE="$SCRIPT_DIR/Brewfile"
BUNFILE="$SCRIPT_DIR/Bunfile"

DRY_RUN=false
[[ "$1" == "--dry-run" ]] && DRY_RUN=true

info() { echo "ℹ️  $1"; }
warn() { echo "⚠️  $1"; }
success() { echo "✅ $1"; }

run_cmd() {
	if $DRY_RUN; then
		echo "   [dry-run] $*"
	else
		"$@"
	fi
}

# Parse Brewfile for expected packages
parse_brewfile() {
	local type=$1
	grep "^$type " "$BREWFILE" 2>/dev/null | sed -E "s/^$type \"([^\"]+)\".*/\1/" | sort -u
}

# Cleanup Homebrew formulae
cleanup_brew() {
	info "Checking Homebrew formulae..."

	local expected=$(parse_brewfile "brew")
	local installed=$(brew leaves | sort -u)

	local orphans=()
	while IFS= read -r pkg; do
		# Check if package (or its short name) is in expected list
		local short_name="${pkg##*/}"  # Handle tap/name format
		if ! echo "$expected" | grep -qxF "$pkg" && ! echo "$expected" | grep -qxF "$short_name"; then
			orphans+=("$pkg")
		fi
	done <<< "$installed"

	if [[ ${#orphans[@]} -eq 0 ]]; then
		success "No orphan formulae found"
	else
		warn "Orphan formulae: ${orphans[*]}"
		for pkg in "${orphans[@]}"; do
			run_cmd brew uninstall --ignore-dependencies "$pkg"
		done
	fi
}

# Cleanup Homebrew casks
cleanup_casks() {
	info "Checking Homebrew casks..."

	local expected=$(parse_brewfile "cask")
	local installed=$(brew list --cask 2>/dev/null | sort -u)

	local orphans=()
	while IFS= read -r pkg; do
		[[ -z "$pkg" ]] && continue
		if ! echo "$expected" | grep -qxF "$pkg"; then
			orphans+=("$pkg")
		fi
	done <<< "$installed"

	if [[ ${#orphans[@]} -eq 0 ]]; then
		success "No orphan casks found"
	else
		warn "Orphan casks: ${orphans[*]}"
		for pkg in "${orphans[@]}"; do
			run_cmd brew uninstall --cask "$pkg"
		done
	fi
}

# Cleanup Homebrew taps
cleanup_taps() {
	info "Checking Homebrew taps..."

	local expected=$(parse_brewfile "tap")
	local installed=$(brew tap | sort -u)

	local orphans=()
	while IFS= read -r tap; do
		[[ -z "$tap" ]] && continue
		if ! echo "$expected" | grep -qxF "$tap"; then
			orphans+=("$tap")
		fi
	done <<< "$installed"

	if [[ ${#orphans[@]} -eq 0 ]]; then
		success "No orphan taps found"
	else
		warn "Orphan taps: ${orphans[*]}"
		for tap in "${orphans[@]}"; do
			run_cmd brew untap "$tap"
		done
	fi
}

# Cleanup bun global packages
cleanup_bun() {
	info "Checking bun global packages..."

	if ! command -v bun &>/dev/null; then
		warn "bun not installed, skipping"
		return
	fi

	local expected=$(sed 's/#.*//' "$BUNFILE" | grep -v '^$' | sort -u)
	# Parse bun pm ls -g output: "├── package@version" or "└── package@version"
	local installed=$(bun pm ls -g 2>/dev/null | grep -E '^[├└]' | sed 's/^[├└]── //' | sed 's/@[^@]*$//' | sort -u)

	if [[ -z "$installed" ]]; then
		success "No bun global packages installed"
		return
	fi

	local orphans=()
	while IFS= read -r pkg; do
		[[ -z "$pkg" ]] && continue
		if ! echo "$expected" | grep -qxF "$pkg"; then
			orphans+=("$pkg")
		fi
	done <<< "$installed"

	if [[ ${#orphans[@]} -eq 0 ]]; then
		success "No orphan bun packages found"
	else
		warn "Orphan bun packages: ${orphans[*]}"
		for pkg in "${orphans[@]}"; do
			run_cmd bun remove -g "$pkg"
		done
	fi
}

# Cleanup npm global packages (legacy)
cleanup_npm() {
	info "Checking npm global packages..."

	if ! command -v npm &>/dev/null; then
		warn "npm not installed, skipping"
		return
	fi

	# Use Bunfile as source of truth (migrated from npm to bun)
	local expected=$(sed 's/#.*//' "$BUNFILE" | grep -v '^$' | sort -u)
	local installed=$(npm list -g --depth=0 --parseable 2>/dev/null | tail -n +2 | xargs -n1 basename | sort -u)

	# Packages to never uninstall (core tools)
	local skip_list=("npm" "corepack")

	local orphans=()
	while IFS= read -r pkg; do
		[[ -z "$pkg" ]] && continue
		# Skip core packages
		[[ " ${skip_list[*]} " == *" $pkg "* ]] && continue
		if ! echo "$expected" | grep -qxF "$pkg"; then
			orphans+=("$pkg")
		fi
	done <<< "$installed"

	if [[ ${#orphans[@]} -eq 0 ]]; then
		success "No orphan npm packages found"
	else
		warn "Orphan npm packages: ${orphans[*]}"
		for pkg in "${orphans[@]}"; do
			run_cmd npm uninstall -g "$pkg"
		done
	fi
}

main() {
	echo "🧹 Dotfiles Cleanup Script"
	echo "=========================="
	$DRY_RUN && echo "🔍 DRY RUN MODE - no changes will be made"
	echo ""

	[[ ! -f "$BREWFILE" ]] && { warn "Brewfile not found: $BREWFILE"; exit 1; }
	[[ ! -f "$BUNFILE" ]] && { warn "Bunfile not found: $BUNFILE"; exit 1; }

	cleanup_brew
	cleanup_casks
	cleanup_taps
	cleanup_bun
	cleanup_npm

	echo ""
	if $DRY_RUN; then
		info "Run without --dry-run to apply changes"
	else
		success "Cleanup complete!"
		info "Run 'brew autoremove && brew cleanup' to remove unused dependencies"
	fi
}

main "$@"
