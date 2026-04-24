#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

staging_dir="$(mktemp -d)"
cleanup() {
    rm -rf "${staging_dir}"
}
trap cleanup EXIT

cp -R metadata.json contents screenshots LICENSE README.md "${staging_dir}/"

kpackagetool6 -t Plasma/Applet -u "${staging_dir}" || kpackagetool6 -t Plasma/Applet -i "${staging_dir}"
