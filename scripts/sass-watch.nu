#!/usr/bin/env nu

cd (git rev-parse --show-toplevel)
print $'(ansi green)Watching Sass files for changes…(ansi reset)("\n")'
(
  dart-sass
  --load-path node_modules/
  --no-source-map
  --style compressed
  --watch
  assets/css/404.scss:assets/css/404.min.css
  assets/css/home.scss:assets/css/home.min.css
  assets/css/journal.scss:assets/css/journal.min.css
  assets/css/post.scss:assets/css/post.min.css
)
