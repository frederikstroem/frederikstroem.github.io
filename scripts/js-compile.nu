#!/usr/bin/env nu

cd $"(git rev-parse --show-toplevel)/assets/js"
let out_path = "main.min.js"
let backup_path = "main.min.js.bak"
if ($out_path | path exists) {
  print $'(ansi yellow)Backing up existing JavaScript file…(ansi reset)'
  mv -fv $out_path $backup_path
}
try {
  print $'(ansi green)Compiling JavaScript with Google Closure Compiler…(ansi reset)("\n")'
  (
    closure-compiler
    --compilation_level SIMPLE
    --js "**.js"
    --js_output_file main.min.js
  )
  print $'(ansi green_bold)("\n")JavaScript compiled successfully!(ansi reset)'
  if ($backup_path | path exists) {
    try { rm -fv $backup_path }
  }
} catch {
  if ($backup_path | path exists) {
    print $'("\n")(ansi red)JavaScript compilation failed! Attemping to restore from backup file…(ansi reset)'
    mv -fv $backup_path $out_path
  } else {
    print $'("\n")(ansi red)JavaScript compilation failed! No backup file to restore.(ansi reset)'
  }
}
