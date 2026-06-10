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
	print_status "Creating Mackup backup..."

	if ! check_command "mackup"; then
		print_error "mackup not found, skipping backup"
		return 0
	fi

	if mackup backup --force &>/dev/null; then
		print_success "Mackup backup completed"
		return 0
	else
		print_error "Mackup backup failed"
		return 0
	fi
}

main() {
	echo "🚀 Preparing migration packages and configurations..."
	echo ""

	local success_count=0
	local total_tasks=3

	if dumpBrew; then
		((success_count++))
	fi

	if dumpBun; then
		((success_count++))
	fi

	if dumpMackup; then
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
