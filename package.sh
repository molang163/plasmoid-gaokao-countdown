#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

package_path="dist/gaokao-countdown.plasmoid"
package_files=(
    metadata.json
    contents
    LICENSE
    README.md
)

mkdir -p dist
rm -f "${package_path}"

if command -v cmake >/dev/null 2>&1; then
    cmake -E tar cf "${package_path}" --format=zip "${package_files[@]}"
elif command -v 7z >/dev/null 2>&1; then
    7z a -tzip "${package_path}" "${package_files[@]}" >/dev/null
elif command -v bsdtar >/dev/null 2>&1; then
    bsdtar -a -cf "${package_path}" "${package_files[@]}"
else
    printf 'Missing archive tool: install cmake, 7z, or bsdtar.\n' >&2
    exit 1
fi

printf 'Created %s\n' "${package_path}"
