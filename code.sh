#!/usr/bin/env bash
set -exuo pipefail
git pull --all
GIT_MERGE_AUTOEDIT=no git merge nixpkgs/main
git push
cd ~/code
./auth-rebuild.sh
