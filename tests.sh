#!/bin/bash

# see https://github.com/lehmannro/assert.sh

# Test is very minimal. It checks for the existence of expected files, skipping
# those which are instrumental to the build process. For example, we can safely skip
# testing the existence of the SASS compiler if we test the existence of the compiled
# css file.

set -e

. ./assert.sh

function fileExists() {
  ls $1
}

files="bin/modd elm-package.json modd.conf \
       pages/dummy/index.html styles/dummy/main.scss interop/dummy/app.js src/Dummy/Main.elm \
       build/dummy/index.html build/dummy/interop.js build/dummy/main.js build/dummy/main.css"

for file in $files
do
  assert_raises "ls dummy/$file" 0
done

assert_end examples
