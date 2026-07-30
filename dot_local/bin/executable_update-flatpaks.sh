#!/bin/bash
REPO_DIR="$HOME/home/user/Documents/fedora-atomic_provisioning/Chezmoi-Dotfiles"
cd "$REPO_DIR" || exit 1
flatpak list --app --columns=application > flatpaks.txt
git add flatpaks.txt
git diff-index --quiet HEAD || (git commit -m "Update flatpak list: $(date +%F)" && git push)
