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

  enterTest = ''
    ./scripts/journal-dates-sync.nu test
  '';
}
