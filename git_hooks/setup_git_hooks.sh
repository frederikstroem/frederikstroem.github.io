#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")" || exit 1

# Color definitions.
readonly RED='\033[0;31m'
readonly BOLD_RED='\033[1;31m'
readonly BLUE='\033[0;34m'
readonly BOLD_BLUE='\033[1;34m'
readonly CYAN='\033[0;36m'
readonly BOLD_CYAN='\033[1;36m'
readonly YELLOW='\033[0;33m'
readonly BOLD_YELLOW='\033[1;33m'
readonly GREEN='\033[0;32m'
readonly BOLD_GREEN='\033[1;32m'
readonly PURPLE='\033[0;35m'
readonly BOLD_PURPLE='\033[1;35m'
readonly RESET='\033[0m'

# Function to print colored output to stdout.
print_colored() {
    local color="$1"
    shift
    echo -e "${color}$*${RESET}"
}

# Function to print colored output to stderr.
print_colored_err() {
    local color="$1"
    shift
    echo -e "${color}$*${RESET}" >&2
}

# Get the repository root.
repo_root=$(git rev-parse --show-toplevel)
print_colored "${BOLD_CYAN}" "🔍 Repository root found at: ${repo_root}"

# Check if this is a git worktree by examining if .git is a file instead of a directory.
git_path="${repo_root}/.git"

if [ -f "$git_path" ]; then
    echo "" >&2
    print_colored_err "${BOLD_RED}" "╭─────────────────────────────────────────────────╮"
    print_colored_err "${BOLD_RED}" "│  ❌  GIT WORKTREE DETECTED                      │"
    print_colored_err "${BOLD_RED}" "╰─────────────────────────────────────────────────╯"
    echo "" >&2

    print_colored_err "${RED}" "This appears to be a git worktree, not the main repository."
    echo "" >&2

    print_colored_err "${BOLD_CYAN}" "ℹ️  Worktree Information:"
    print_colored_err "${CYAN}" "   📁 .git file content:"
    print_colored_err "${BLUE}" "      $(cat "$git_path")"
    print_colored_err "${CYAN}" "   🎯 Actual git directory:"
    print_colored_err "${BLUE}" "      $(git rev-parse --git-common-dir)"
    echo "" >&2

    print_colored_err "${BOLD_YELLOW}" "💡 Why This Matters:"
    print_colored_err "${YELLOW}" "   • Git hooks should be set up in the main repository"
    print_colored_err "${YELLOW}" "   • Worktrees automatically inherit hooks from main repo"
    echo "" >&2

    print_colored_err "${BOLD_GREEN}" "🏠 Main Repository Location:"
    print_colored_err "${GREEN}" "   $(git rev-parse --git-common-dir | sed 's|/.git$||')"
    echo "" >&2

    print_colored_err "${BOLD_YELLOW}" "✨ Next Steps:"
    print_colored_err "${YELLOW}" "   1. Navigate to the main repository"
    print_colored_err "${YELLOW}" "   2. Run the development environment setup there"
    print_colored_err "${YELLOW}" "   3. Git hooks will work in all worktrees automatically"
    echo "" >&2

    exit 1
elif [ ! -d "$git_path" ]; then
    echo "" >&2
    print_colored_err "${BOLD_RED}" "❌ Error: ${git_path} is neither a file nor a directory."
    print_colored_err "${RED}" "   Unexpected git repository setup detected."
    echo "" >&2
    exit 1
fi

# Define the source (custom hooks) and target (git hooks) directories.
hooks_source="${repo_root}/git_hooks/hooks"
hooks_target="${repo_root}/.git/hooks"

# Check that the git_hooks/hooks directory exists.
if [ ! -d "${hooks_source}" ]; then
  print_colored_err "${BOLD_RED}" "❌ Error: ${hooks_source} directory does not exist."
  exit 1
fi

# Track hook operations for summary.
hooks_linked=0
hooks_skipped=0
hooks_updated=0
total_hooks=0

echo ""
print_colored "${BOLD_PURPLE}" "🔗 Linking hooks from ${hooks_source} to ${hooks_target}"

# Loop over each file in git_hooks/hooks.
for hook in "${hooks_source}"/*; do
  # Only process files (skip directories, if any).
  if [ ! -f "$hook" ]; then
    continue
  fi

  ((++total_hooks)) # Use pre-increment (++var) instead of post-increment (var++) to avoid issues with 'set -e'.
  hook_name=$(basename "$hook")
  target_hook="${hooks_target}/${hook_name}"

  # Check if the hook already exists in .git/hooks.
  if [ -e "$target_hook" ]; then
    # If it's already a symlink that points to the correct file, leave it.
    if [ -L "$target_hook" ] && [ "$(readlink "$target_hook")" = "$hook" ]; then
      print_colored "${GREEN}" "   ✅ Hook '${hook_name}' is already correctly linked. Skipping."
      ((++hooks_skipped))
      continue
    fi
    # Otherwise, remove the existing file/symlink.
    print_colored "${YELLOW}" "   🔄 Updating existing hook: ${hook_name}"
    rm -f "$target_hook"
    ((++hooks_updated))
  else
    ((++hooks_linked))
  fi

  print_colored "${BLUE}" "   🔗 Linking '${hook_name}'…"
  ln -s "$hook" "$target_hook"
done

echo ""
print_colored "${BOLD_GREEN}" "╭─────────────────────────────────────────────────╮"
print_colored "${BOLD_GREEN}" "│  ✅  GIT HOOKS SETUP COMPLETE                   │"
print_colored "${BOLD_GREEN}" "╰─────────────────────────────────────────────────╯"
echo ""

print_colored "${BOLD_CYAN}" "📊 Summary:"
if [ $total_hooks -eq 0 ]; then
    print_colored "${YELLOW}" "   • No hook files found in ${hooks_source}"
else
    print_colored "${CYAN}" "   • ${total_hooks} total hook(s) processed"
    [ $hooks_linked -gt 0 ] && print_colored "${GREEN}" "   • ${hooks_linked} hook(s) newly linked"
    [ $hooks_updated -gt 0 ] && print_colored "${YELLOW}" "   • ${hooks_updated} hook(s) updated"
    [ $hooks_skipped -gt 0 ] && print_colored "${GREEN}" "   • ${hooks_skipped} hook(s) already up-to-date"
fi

echo ""
if [ $total_hooks -eq 0 ]; then
    print_colored "${YELLOW}" "⚠️  No hooks were found to set up."
elif [ $hooks_skipped -eq $total_hooks ]; then
    print_colored "${BOLD_GREEN}" "🚀 Git hooks were already configured!"
elif [ $((hooks_linked + hooks_updated)) -gt 0 ]; then
    print_colored "${BOLD_GREEN}" "✅ Git hooks have been successfully updated and are ready to use!"
else
    print_colored "${BOLD_GREEN}" "🎉 Git hooks are now active and ready to use!"
fi

exit 0
