#!/usr/bin/env bash

rm -rf exports
mkdir -p exports/web

./bundle_server.sh
godot-headless --path src --export web "$(readlink -f exports/web/index.html)"
butler push exports/web creikey/space-fight:web
