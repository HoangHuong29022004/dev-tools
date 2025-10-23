#!/bin/bash
# Project Manager wrapper
exec python3 "$(dirname "$0")/manage.py" "$@"

