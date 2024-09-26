#!/bin/sh
echo -ne '\033c\033]0;Maze Game\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Maze Game.x86_64" "$@"
