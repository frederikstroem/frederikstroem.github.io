# [frederikstroem.com](https://frederikstroem.com) Source Code
[![Renovate Enabled](https://img.shields.io/badge/renovate-enabled-brightgreen.svg?logo=renovate)](https://renovatebot.com/)
[![pages-build-deployment](https://img.shields.io/github/actions/workflow/status/frederikstroem/frederikstroem.github.io/pages%2Fpages-build-deployment?logo=github&label=pages-build-deployment)](https://github.com/frederikstroem/frederikstroem.github.io/actions/workflows/pages/pages-build-deployment)
[![CodeQL](https://img.shields.io/github/actions/workflow/status/frederikstroem/frederikstroem.github.io/github-code-scanning%2Fcodeql?logo=github&label=github-code-scanning)](https://github.com/frederikstroem/frederikstroem.github.io/actions/workflows/github-code-scanning/codeql)

The source code for my personal web page [frederikstroem.com](https://frederikstroem.com)

**3rd party tools, libraries and services used in this project:**

- Served with [Jekyll](https://jekyllrb.com/).
- Hosted on [GitHub Pages](https://pages.github.com/).
- Icons from [Font Awesome](https://fontawesome.com/).
- CSS styled with [Sass](https://sass-lang.com/), [Bulma](https://bulma.io/) and [Rouge](https://rouge.jneen.net/).
- JavaScript compiled with [Google Closure Compiler](https://developers.google.com/closure/compiler/).
- VS Code tasks located in `.vscode/tasks.json`, are used during development.

## Ruby
To manage Ruby versions I use [rbenv](https://github.com/rbenv/rbenv).

Make sure to have an updated version of Ruby installed before proceeding.

Ensure all dependencies are installed:
```bash
$ bundle install
```

To run the Jekyll server locally:
```bash
$ bundle exec jekyll serve
```

To update the Ruby gems:
```bash
$ bundle update
```

## npm
To manage Node versions I use [Node Version Manager (nvm)](https://github.com/nvm-sh/nvm).

## Sass
Because Dart Sass interferes with Ruby Sass:
```bash
$ whereis sass
sass: /home/username/.rbenv/shims/sass /home/username/.nvm/versions/node/v22.3.0/bin/sass
```
I use `npx` to easily run Dart Sass, exporting the npm path to the shell would also be possible:
```bash
$ export PATH="/home/username/.nvm/versions/node/v22.3.0/bin:$PATH"
```

To install Dart Sass globally:

```bash
$ npm install -g sass
```

## Google Closure Compiler
To install Google Closure Compiler globally:

```bash
$ npm install -g google-closure-compiler
```
