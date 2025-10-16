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

  imports = [
    inputs.parallel-git-hooks.devenvModule
  ];

  packages = with pkgs; [
    nushell
    dart-sass
    closurecompiler
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
      exec = builtins.readFile ./scripts/sass-compile.nu;
      package = pkgs.nushell;
      binary = "nu";
    };

    sass-watch = {
      exec = builtins.readFile ./scripts/sass-watch.nu;
      package = pkgs.nushell;
      binary = "nu";
    };

    js-compile = {
      exec = builtins.readFile ./scripts/js-compile.nu;
      package = pkgs.nushell;
      binary = "nu";
    };

    journal-dates-sync = {
      exec = builtins.readFile ./scripts/journal-dates-sync.nu;
      package = pkgs.nushell;
      binary = "nu";
    };

  };

  tasks = {

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

  parallel-git-hooks = {
    enable = true;
    # logLevel = "DEBUG";
    hooks = [
      {
        name = "Compile Sass files";
        cmd = "sass-compile";
        # Filter only compiled output files (*.min.css).
        fileFilter = ''\.min\.css$'';
      }
      {
        name = "Compile JavaScript files";
        cmd = "js-compile";
        # Filter only compiled output files (*.min.js).
        fileFilter = ''\.min\.js$'';
      }
      {
        name = "Update journal dates";
        cmd = "journal-dates-sync";
        # Get unstaged files that were modified by the journal-dates-sync script (/_posts/*.md).
        fileFilter = ''^_posts/.*\.md$'';
      }
    ];
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

  enterTest = ''
    ./scripts/journal-dates-sync.nu test
  '';
}
