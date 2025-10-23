#!/bin/bash
# Wrapper cho mkproject.py
exec python3 "$(dirname "$0")/mkproject.py" "$@"

