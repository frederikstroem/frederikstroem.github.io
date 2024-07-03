#!/usr/bin/env bash

if ! bundle exec jekyll serve
then
    # If command fails, give some hints...
    echo '----------------'
    echo 'Make sure to have an updated version of Ruby installed, rbenv is recommended: https://github.com/rbenv/rbenv'
    echo 'Remember to run "bundle install" before first run.'
    echo 'If all else fails, see https://github.com/github/pages-gem'
fi
