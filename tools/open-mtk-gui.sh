#!/bin/sh
set -eu
if [ "$#" -ne 1 ]; then
  echo 'Usage: sh tools/open-mtk-gui.sh /absolute/path/to/mtkclient' >&2
  exit 2
fi
cd "$1"
exec ./.venv/bin/python mtk_gui.py
