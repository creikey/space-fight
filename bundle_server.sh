#!/usr/bin/env bash

scp -r signalling_server root@droplet:/var/www/html/

ssh droplet sudo -u nodejs pm2 restart server

#godot-headless --path src --export-pack web "$(readlink -f exports/particles-life.pck)" && scp exports/particles-life.pck extserver:/home/ubuntu/
