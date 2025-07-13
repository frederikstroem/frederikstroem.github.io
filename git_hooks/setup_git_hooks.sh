#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")" || exit 1

# Get the repository root using Git.
repo_root=$(git rev-parse --show-toplevel)
echo "Repository root found at: ${repo_root}"

# Define the source (custom hooks) and target (git hooks) directories.
hooks_source="${repo_root}/git_hooks/hooks"
hooks_target="${repo_root}/.git/hooks"

# Check that the git_hooks/hooks directory exists.
if [ ! -d "${hooks_source}" ]; then
  echo "Error: ${hooks_source} directory does not exist." >&2
  exit 1
fi

echo "Linking hooks from ${hooks_source} to ${hooks_target}"

# Loop over each file in git_hooks/hooks.
for hook in "${hooks_source}"/*; do
  # Only process files (skip directories, if any).
  if [ ! -f "$hook" ]; then
    continue
  fi

  hook_name=$(basename "$hook")
  target_hook="${hooks_target}/${hook_name}"

  # Check if the hook already exists in .git/hooks.
  if [ -e "$target_hook" ]; then
    # If it’s already a symlink that points to the correct file, leave it.
    if [ -L "$target_hook" ] && [ "$(readlink "$target_hook")" = "$hook" ]; then
      echo "Hook '${hook_name}' is already correctly linked. Skipping."
      continue
    fi
    # Otherwise, remove the existing file/symlink.
    echo "Removing existing hook: ${target_hook}"
    rm -f "$target_hook"
  fi

  echo "Linking '${hook_name}'..."
  ln -s "$hook" "$target_hook"
done

echo "Git hooks setup complete."
