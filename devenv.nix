{ pkgs, lib, config, inputs, ... }:

{
  overlays = [
    (final: prev: {
      # https://github.com/bobvanderlinden/nixpkgs-ruby/issues/89
      ruby_3_2 = inputs.nixpkgs-ruby.packages.${prev.stdenv.system}."ruby-3.2".override {
        openssl = prev.openssl_1_1;
      };
    })
  ];

  packages = with pkgs; [
    nushell
  ];

  languages = {
    ruby = {
      enable = true;
      package = pkgs.ruby_3_2;
      bundler = {
        enable = true;
        package = pkgs.ruby_3_2;
      };
    };
    javascript = {
      enable = true;
      npm = {
        enable = true;
        install.enable = true;
      };
    };
  };

  processes = {

    jekyll-serve = {
      exec = "bundle exec jekyll serve";
    };

  };

  scripts = {

    sass-compile = {
      exec = ''
        print $'(ansi green)Compiling Sass files…(ansi reset)("\n")'
        (
          ${pkgs.dart-sass}/bin/sass
          --load-path node_modules/
          --no-source-map
          --style compressed
          assets/css/404.scss:assets/css/404.min.css
          assets/css/home.scss:assets/css/home.min.css
          assets/css/journal.scss:assets/css/journal.min.css
          assets/css/post.scss:assets/css/post.min.css
        )
      '';
      package = pkgs.nushell;
      binary = "nu";
    };

    sass-watch = {
      exec = ''
        print $'(ansi green)Watching Sass files for changes…(ansi reset)("\n")'
        (
          ${pkgs.dart-sass}/bin/sass
          --load-path node_modules/
          --no-source-map
          --style compressed
          --watch
          assets/css/404.scss:assets/css/404.min.css
          assets/css/home.scss:assets/css/home.min.css
          assets/css/journal.scss:assets/css/journal.min.css
          assets/css/post.scss:assets/css/post.min.css
        )
      '';
      package = pkgs.nushell;
      binary = "nu";
    };

    js-compile = {
      exec = ''
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
            ${pkgs.closurecompiler}/bin/closure-compiler
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
      '';
      package = pkgs.nushell;
      binary = "nu";
    };

  };

  tasks = {

    "init:git-hooks" = {
      exec = "./git_hooks/setup_git_hooks.sh";
      after = [ "devenv:enterShell" ];
    };
    "init:bundle" = {
      exec = "bundle install";
      after = [ "devenv:enterShell" ];
    };
    "init:npm" = {
      exec = "npm install";
      after = [ "devenv:enterShell" ];
    };

    "update:bundle" = {
      exec = "bundle update";
    };
    "update:npm" = {
      exec = "npm update";
    };

  };

  enterShell = ''
    echo
    echo "💎 `ruby --version`"
    echo "📦 `bundle --version`"
    echo " Node `node --version`"
    echo "📦 NPM `npm --version`"
    echo
    echo "❓️ Run \"devenv info\" to print information about this developer environment."
  '';
}
