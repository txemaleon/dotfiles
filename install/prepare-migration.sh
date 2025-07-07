#!/usr/bin/env zsh

SCRIPT_DIR=$(dirname "${0:A}")
BREWFILE="$SCRIPT_DIR/Brewfile"
NPMFILE="$SCRIPT_DIR/Npmfile"

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

dumpNPM() {
	print_status "Generating NPM global packages list..."

	if ! check_command "npm"; then
		print_error "npm not found, skipping NPM packages dump"
		return 0
	fi

	# Get npm global root directory
	local npm_root
	npm_root=$(npm root -g 2>/dev/null)
	if [ -z "$npm_root" ]; then
		print_error "Could not determine npm global root"
		return 0
	fi

	# Get only package names, filtering out paths and npm itself
	npm list -g --depth=0 --parseable --silent 2>/dev/null |
		grep "^$npm_root/" |
		sed "s|$npm_root/||g" |
		grep -v "^npm$" |
		grep -v "^$" |
		sort >"$NPMFILE"

	local package_count=$(wc -l <"$NPMFILE" | tr -d ' ')
	print_success "NPM packages list updated with $package_count packages"
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

	if dumpNPM; then
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
