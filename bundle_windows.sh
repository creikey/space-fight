mkdir -p exports/win
rm -rf exports/win
mkdir -p exports/win
godot-headless --path src --export win "$(readlink -f exports/win/space_fight.exe)"
