#!/usr/bin/env nu

use std/log

# Get current UTC date in YYYY-MM-DD format.
def get_current_utc_date []: nothing -> string {
    date now | date to-timezone utc | format date "%Y-%m-%d"
}

# Verify that a filename follows the required format and character restrictions.
# Expected format: YYYY-MM-DD-<slug>.md
# Allowed characters in slug: lowercase letters, numbers, hyphens.
# Must end with exactly `.md`.
def verify_filename []: string -> nothing {
    let filename = $in

    # Check if filename ends with .md
    if not ($filename | str ends-with ".md") {
        error make {
            msg: $'Filename "($filename)" must end with .md extension'
        }
    }

    # Check if filename follows the complete pattern: YYYY-MM-DD-<slug>.md
    # Slug can only contain lowercase letters, numbers, and hyphens
    let full_pattern = '^(?P<year>\d{4})-(?P<month>\d{2})-(?P<day>\d{2})-(?P<slug>[a-z0-9-]+)\.md$'
    let match_result = $filename | parse --regex $full_pattern

    if ($match_result | length) == 0 {
        error make {
            msg: $'Filename "($filename)" must follow format YYYY-MM-DD-<slug>.md where slug contains only lowercase letters (a-z), numbers (0-9), and hyphens (-)'
        }
    }

    let parsed = $match_result | first
    let year = $parsed.year | into int
    let month = $parsed.month | into int
    let day = $parsed.day | into int
    let slug = $parsed.slug

    # Validate date ranges
    if $year < 1900 or $year > 2100 {
        error make {
            msg: $'Filename "($filename)" has invalid year ($year). Must be between 1900-2100'
        }
    }

    if $month < 1 or $month > 12 {
        error make {
            msg: $'Filename "($filename)" has invalid month ($month). Must be between 01-12'
        }
    }

    if $day < 1 or $day > 31 {
        error make {
            msg: $'Filename "($filename)" has invalid day ($day). Must be between 01-31'
        }
    }

    # Check for problematic patterns in slug
    if ($slug | str starts-with "-") or ($slug | str ends-with "-") {
        error make {
            msg: $'Filename "($filename)" slug cannot start or end with hyphen'
        }
    }

    if ($slug | str contains "--") {
        error make {
            msg: $'Filename "($filename)" contains double hyphens (--) in slug. Use single hyphens (-) for word separation'
        }
    }
}

# Extract date from filename (YYYY-MM-DD prefix).
def extract_date_from_filename []: string -> string {
    let date_match = $in | parse --regex '^(?P<date>\d{4}-\d{2}-\d{2})-.*'

    if ($date_match | length) == 0 {
        error make {
            msg: $'Filename "($in)" does not contain a valid date prefix in the format YYYY-MM-DD.'
        }
    }

    return ($date_match | first | get date)
}

# Extract the slug from filename after the date prefix (YYYY-MM-DD-).
def extract_slug_from_filename []: string -> string {
    let match_result = $in | parse --regex '^(?P<date>\d{4}-\d{2}-\d{2})-(?P<slug>.+)'

    if ($match_result | length) == 0 {
        error make {
            msg: $'Filename "($in)" does not contain a valid format YYYY-MM-DD-<slug>.'
        }
    }

    let slug = $match_result | first | get slug

    # Error if slug is empty (just whitespace)
    if ($slug | str trim | is-empty) {
        error make {
            msg: $'Filename "($in)" has an empty slug after the date prefix.'
        }
    }

    return $slug
}

# Get journal posts' Git status by running `git status --porcelain=1`.
# Each line is a record with is_new (boolean), filename (string), and path (string).
# Only processes staged changes and fails if unstaged changes exist for the same file.
def get_changed_journal_posts []: nothing -> list<record<is_new: bool, filename: string, path: string>> {
    let git_status_lines = git status --porcelain=1 | lines

    mut changed_posts = []
    mut conflicting_files = []

    for $line in $git_status_lines {
        # Skip empty lines
        if ($line | str trim | is-empty) {
            continue
        }

        # # Ensure line is at least 3 characters long (XY filename)
        # if ($line | str length) < 3 {
        #     continue
        # }

        # Git porcelain format: XY filename
        # X = staged status (position 0)
        # Y = unstaged status (position 1)
        # Filename starts at position 3 (after XY and space)
        let staged_status = $line | str substring 0..<1
        let unstaged_status = $line | str substring 1..<2
        let line_path = $line | str substring 3..
        let line_filename = $line_path | path basename

        # Only process journal posts.
        if not ($line_path | str starts-with "_posts/") {
            continue
        }

        # Verify filename format.
        try {
            $line_filename | verify_filename
        } catch { |e|
            error make {
                msg: $'Invalid filename format for "($line_path)": ($e.msg)'
            }
        }

        # Debug output
        log debug $"Processing ($line_path)"
        log debug $"  Full line: '($line)'"
        log debug $"  Staged status: '($staged_status)'"
        log debug $"  Unstaged status: '($unstaged_status)'"

        # Check if file has staged changes
        let has_staged_changes = match $staged_status {
            "A" => true,  # Added
            "M" => true,  # Modified
            "D" => true,  # Deleted
            "R" => true,  # Renamed
            "C" => true,  # Copied
            _ => false
        }

        # Check if file has unstaged changes
        let has_unstaged_changes = match $unstaged_status {
            "M" => true,  # Modified
            "D" => true,  # Deleted
            _ => false
        }

        log debug $"  Has staged changes: ($has_staged_changes)"
        log debug $"  Has unstaged changes: ($has_unstaged_changes)"

        if $has_staged_changes {
            if $has_unstaged_changes {
                # File has both staged and unstaged changes - this is a conflict
                log debug $"  -> Adding to conflicting files"
                $conflicting_files = $conflicting_files | append $line_path
            } else {
                # File only has staged changes - safe to process
                log debug $"  -> Adding to changed posts"
                let is_new = ($staged_status == "A")

                $changed_posts = $changed_posts | append {
                    is_new: $is_new,
                    filename: $line_filename,
                    path: $line_path
                }
            }
        } else {
            log debug "  -> Skipping (no staged changes)"
        }
    }

    # Fail if there are conflicting files.
    if ($conflicting_files | length) > 0 {
        let file_list = $conflicting_files | str join ', '
        error make --unspanned {
            msg: $"Cannot process files with both staged and unstaged changes. The following files have conflicts: ($file_list).\nPlease either stage all changes or stash unstaged changes before running this script."
        }
    }

    $changed_posts
}

# Parse YAML front matter from Markdown string.
def parse_front_matter []: string -> record {
    # Clear whitespace from the input and ensure it's not empty.
    let content = $in | str trim
    if ($content | is-empty) {
        error make { msg: "Input content is empty" }
    }

    # Split the content into lines to locate the YAML front matter.
    let lines = $content | lines

    # The first line should be the start delimiter (Nushell is zero-indexed).
    if ($lines | get 0 | str trim) != "---" {
        error make { msg: 'YAML front matter must start with "---" at the beginning of the file' }
    }

    # The end delimiter is the first line after the start delimiter that contains "---".
    let delimiter_line__end: int = ($lines | skip 1 | enumerate | str trim | where item == "---" | first | get index) + 1 # `+ 1` is added due to skipping the first line.
    if ($delimiter_line__end | is-empty) {
        error make { msg: "YAML front matter not properly closed" }
    }

    # Extract YAML content into a string.
    let yaml_lines = $lines | slice 1..<$delimiter_line__end
    let yaml_content = $yaml_lines | str join "\n" | from yaml

    # Return the parsed YAML content.
    if ($yaml_content | describe) == nothing {
        return {}
    } else {
        return $yaml_content
    }
}

# Convert a record to YAML front matter format (with --- delimiters).
def record_to_front_matter []: record -> string {
    # This is a simple conversion to YAML format.
    # let yaml_content = $in | to yaml
    # return $"---\n($yaml_content)---"
    #
    # But I'm using a manual approach to ensure a specific format.
    let front_matter_record = $in
    mut front_matter_lines = ["---"]
    $front_matter_lines = $front_matter_lines | append $"layout: ($front_matter_record.layout)"
    $front_matter_lines = $front_matter_lines | append ""
    $front_matter_lines = $front_matter_lines | append $"title: ($front_matter_record.title)"
    if "last_modified" in ($in | columns) {
        $front_matter_lines = $front_matter_lines | append $"last_modified: ($front_matter_record.last_modified)"
    }
    $front_matter_lines = $front_matter_lines | append "---"

    return ($front_matter_lines | str join "\n")
}

# Get post body content after the front matter in a Markdown string.
def get_post_body []: string -> string {
    let content = $in
    # Clear whitespace from the input and ensure it's not empty.
    if ($content | str trim | is-empty) {
        error make { msg: "Input content is empty" }
    }

    # Split the content into lines to locate the YAML front matter.
    let lines = $content | lines

    # The first line should be the start delimiter (Nushell is zero-indexed).
    if ($lines | get 0 | str trim) != "---" {
        error make { msg: 'YAML front matter must start with "---" at the beginning of the file' }
    }

    # Find the end delimiter - the first line after the start delimiter that contains "---".
    let end_delimiter_line: int = ($lines | skip 1 | enumerate | str trim | where item == "---" | first | get index) + 1 # `+ 1` is added due to skipping the first line.
    if ($end_delimiter_line | is-empty) {
        error make { msg: "YAML front matter not properly closed" }
    }

    # Extract the post body content after the front matter.
    let post_body = $lines | slice ($end_delimiter_line + 1).. | str join "\n"

    # Return the post body content.
    if ($post_body | is-empty) {
        return ""
    } else {
        return $post_body
    }
}

# Convert front matter record and post body content into a Markdown string.
def front_matter_and_post_body_to_markdown [
    front_matter: record,
    post_body: string
]: nothing -> string {
    let front_matter_text = $front_matter | record_to_front_matter

    return $"($front_matter_text)\n($post_body)\n"
}

# Sync journal post filenames and `last_modified` dates based on git changes.
#
# - If a post is new, it will be given the current date as its filename prefix and no `last_modified` date will be set.
# - If a post is modified, its `last_modified` date will be updated to the current date.
def main [] {
    # Get the current UTC date.
    let current_date = get_current_utc_date
    log info $"Current UTC date: ($current_date)"

    # Get staged journal posts only.
    let changed_posts = get_changed_journal_posts

    if ($changed_posts | length) == 0 {
        log info "No staged journal posts found."
        return
    }

    log info $"Staged journal posts found: ($changed_posts | length)"

    # Process each changed post, modify filenames and front matter as needed.
    # The front matter structure is currently quite hardcoded and simple, so it should probably be refactored sometime in the future. 🌌
    for $post in $changed_posts {
        log info $"Processing post: ($post.filename) at path: ($post.path)"

        let post_content = open $post.path --raw
        let front_matter = $post_content | parse_front_matter
        let post_body = $post_content | get_post_body

        # Start with an empty front matter and rebuild.
        mut new_front_matter = {}

        # Copy over the essential fields
        $new_front_matter = ($new_front_matter | insert layout $front_matter.layout)
        $new_front_matter = ($new_front_matter | insert title $front_matter.title)

        if $post.is_new {
            # For new posts, set the filename to current date and don't add last_modified.
            let slug = $post.filename | extract_slug_from_filename

            # If the filename has changed, rename the file.
            let new_filename = $"($current_date)-($slug)"
            if $new_filename != $post.filename {
                let new_path = $post.path | path dirname | path join $new_filename
                # Fail if the new path already exists.
                if ($new_path | path exists) {
                    error make {
                        msg: $'Cannot rename "($post.path)" to "($new_path)": file already exists.'
                    }
                } else {
                    mv -v $post.path $new_path
                }
            }

            # Reconstruct the full post content with the new front matter and body.
            let new_post_content = front_matter_and_post_body_to_markdown $new_front_matter $post_body

            # Overwrite the post content with the new front matter and body.
            let new_path = $post.path | path dirname | path join $new_filename
            $new_post_content | save -f $new_path
        } else {
            # For modified posts, conditionally add `last_modified` field.
            let filename_date = $post.filename | extract_date_from_filename

            # If filename is a different date than current, add `last_modified` with current date.
            if $filename_date != $current_date {
                $new_front_matter = ($new_front_matter | upsert last_modified $current_date)
            }

            # Reconstruct the full post content with the new front matter and body.
            let new_post_content = front_matter_and_post_body_to_markdown $new_front_matter $post_body

            # Overwrite the post content with the new front matter and body.
            $new_post_content | save -f $post.path
        }
    }

    exit 0
}

# Test some of the more complex functions.
# This should probably be refactored one day… 🙃
def "main test" [] {
    use std/assert

    # Test `parse_front_matter`
    do {
        # Test a simple front matter.
        do {
            let test_content = '
                ---
                layout: post

                title: Test post
                last_modified: 1970-01-01
                ---
                This is a test post.

                Some more content.

                ```python
                print("Hello, world!")
                ```
            '
            let parsed = $test_content | parse_front_matter

            # Assert the parsed front matter has the expected structure
            assert equal ($parsed | get layout) "post"
            assert equal ($parsed | get title) "Test post"
            assert equal ($parsed | get last_modified) "1970-01-01"

            # Assert it's a record with exactly 3 keys
            assert equal ($parsed | columns | length) 3

            # Assert the expected keys are present
            assert ($parsed | columns | "layout" in $in)
            assert ($parsed | columns | "title" in $in)
            assert ($parsed | columns | "last_modified" in $in)
        }

        # Test empty YAML front matter.
        do {
            let empty_yaml_content = '
                ---
                ---
                Some content after empty front matter.
            '
            let parsed = $empty_yaml_content | parse_front_matter

            # Should return empty record
            assert equal ($parsed | columns | length) 0
        }

        # Test missing end delimiter raises an error.
        do {
            let invalid_content = '
                ---
                layout: post
                title: Test post
                This content has no closing delimiter

                Some more content.
            '

            # This should raise an error.
            let failed = try {
                $invalid_content | parse_front_matter
                false
            } catch {
                true
            }

            assert $failed
        }
    }

    # Test `extract_date_from_filename`
    do {
        # Test valid date extraction.
        do {
            let filename = "2023-10-01-my-post.md"
            let extracted_date = $filename | extract_date_from_filename
            assert equal $extracted_date "2023-10-01"
        }
        # Test filename without date prefix raises an error.
        do {
            let invalid_filename = "my-post.md"
            let failed = try {
                $invalid_filename | extract_date_from_filename
                false
            } catch {
                true
            }
            assert $failed
        }
        # Test filename with invalid date format raises an error.
        do {
            let invalid_filename = "2023-x0-01-my-post.md"
            let failed = try {
                $invalid_filename | extract_date_from_filename
                false
            } catch {
                true
            }
            assert $failed
        }
    }

    # Test `extract_slug_from_filename`
    do {
        # Test valid slug extraction.
        do {
            let filename = "2023-10-01-i-love-nushell.md"
            let extracted_slug = $filename | extract_slug_from_filename
            assert equal $extracted_slug "i-love-nushell.md"
        }

        # Test slug extraction with minimal valid slug.
        do {
            let filename = "2023-10-01-a"
            let extracted_slug = $filename | extract_slug_from_filename
            assert equal $extracted_slug "a"
        }

        # Test slug extraction with complex slug.
        do {
            let filename = "2023-10-01-complex-post-with-many-dashes-and-numbers-123.md"
            let extracted_slug = $filename | extract_slug_from_filename
            assert equal $extracted_slug "complex-post-with-many-dashes-and-numbers-123.md"
        }

        # Test filename without date prefix raises an error.
        do {
            let invalid_filename = "my-post.md"
            let failed = try {
                $invalid_filename | extract_slug_from_filename
                false
            } catch {
                true
            }
            assert $failed
        }

        # Test filename with empty slug raises an error.
        do {
            let invalid_filename = "2023-10-01-"
            let failed = try {
                $invalid_filename | extract_slug_from_filename
                false
            } catch {
                true
            }
            assert $failed
        }

        # Test filename with whitespace-only slug raises an error.
        do {
            let invalid_filename = "2023-10-01-   "
            let failed = try {
                $invalid_filename | extract_slug_from_filename
                false
            } catch {
                true
            }
            assert $failed
        }

        # Test filename with invalid date format raises an error.
        do {
            let invalid_filename = "2023-x0-01-my-post.md"
            let failed = try {
                $invalid_filename | extract_slug_from_filename
                false
            } catch {
                true
            }
            assert $failed
        }
    }

    # Test `verify_filename`
    do {
        # Test valid filenames
        do {
            "2023-10-01-my-post.md" | verify_filename  # Should not error
            "2024-12-31-hello-world.md" | verify_filename  # Should not error
            "2023-01-01-test-123.md" | verify_filename  # Should not error
            "2023-05-15-simple-slug.md" | verify_filename  # Should not error
        }

        # Test invalid extension
        do {
            let failed = try {
                "2023-10-01-my-post.txt" | verify_filename
                false
            } catch {
                true
            }
            assert $failed
        }

        # Test uppercase letters in slug
        do {
            let failed = try {
                "2023-10-01-My-Post.md" | verify_filename
                false
            } catch {
                true
            }
            assert $failed
        }

        # Test spaces in slug
        do {
            let failed = try {
                "2023-10-01-my post.md" | verify_filename
                false
            } catch {
                true
            }
            assert $failed
        }

        # Test dots in slug
        do {
            let failed = try {
                "2023-10-01-my.post.md" | verify_filename
                false
            } catch {
                true
            }
            assert $failed
        }

        # Test non-ASCII characters
        do {
            let failed = try {
                "2023-10-01-my-pøst.md" | verify_filename
                false
            } catch {
                true
            }
            assert $failed
        }

        # Test double hyphens
        do {
            let failed = try {
                "2023-10-01-my--post.md" | verify_filename
                false
            } catch {
                true
            }
            assert $failed
        }

        # Test leading hyphen in slug
        do {
            let failed = try {
                "2023-10-01--post.md" | verify_filename
                false
            } catch {
                true
            }
            assert $failed
        }

        # Test invalid date format
        do {
            let failed = try {
                "23-10-01-my-post.md" | verify_filename
                false
            } catch {
                true
            }
            assert $failed
        }

        # Test invalid month
        do {
            let failed = try {
                "2023-13-01-my-post.md" | verify_filename
                false
            } catch {
                true
            }
            assert $failed
        }

        # Test invalid day
        do {
            let failed = try {
                "2023-12-32-my-post.md" | verify_filename
                false
            } catch {
                true
            }
            assert $failed
        }
    }

    print $"(ansi green_bold)✅ All tests for `($env.CURRENT_FILE | path basename)` passed!(ansi reset)"
    exit 0
}
