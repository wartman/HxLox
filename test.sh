#!/bin/bash

# Just making testing a tad faster

echo 'BUILD'
echo '-----'
haxe build.hxml
echo ''

echo ''
echo 'INTERPRET'
echo '---------'
neko bin/quirk.n run
echo ''

echo ''
echo 'GEN JS'
echo '------'
neko bin/quirk.n gen --js test/main bin/test.js
node bin/test.js

echo ''
echo 'GEN NODE'
echo '------'
neko bin/quirk.n gen --node run bin/test-node

# neko bin/quirk.n gen --php run bin/test_php