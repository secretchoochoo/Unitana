#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
APP_ROOT="${REPO_ROOT}/app/unitana"
ANDROID_GRADLE="${APP_ROOT}/android/app/build.gradle.kts"
ANDROID_KEY_EXAMPLE="${APP_ROOT}/android/key.properties.example"

if rg -n 'com\.example\.unitana' \
  "${APP_ROOT}/android" \
  "${APP_ROOT}/ios" \
  "${APP_ROOT}/macos" \
  "${APP_ROOT}/linux" \
  -g '!build' >/tmp/unitana_release_config_example_ids.txt; then
  echo "Found example platform identifiers that must be replaced:"
  cat /tmp/unitana_release_config_example_ids.txt
  exit 1
fi

if ! rg -q 'namespace = "app\.unitana"' "${ANDROID_GRADLE}"; then
  echo "Android namespace is not set to app.unitana."
  exit 1
fi

if ! rg -q 'applicationId = "app\.unitana"' "${ANDROID_GRADLE}"; then
  echo "Android applicationId is not set to app.unitana."
  exit 1
fi

if rg -q 'signingConfigs\.getByName\("debug"\)' "${ANDROID_GRADLE}"; then
  echo "Android release build still references the debug signing config."
  exit 1
fi

if ! rg -q 'create\("release"\)' "${ANDROID_GRADLE}"; then
  echo "Android release signing config is not defined."
  exit 1
fi

if ! rg -q 'signingConfig = signingConfigs\.getByName\("release"\)' "${ANDROID_GRADLE}"; then
  echo "Android release build is not wired to the release signing config."
  exit 1
fi

if ! rg -q 'key\.properties' "${ANDROID_GRADLE}"; then
  echo "Android release signing is not wired through key.properties."
  exit 1
fi

if [[ ! -f "${ANDROID_KEY_EXAMPLE}" ]]; then
  echo "Missing android/key.properties.example release-signing template."
  exit 1
fi

echo "✅ verify_release_config.sh passed"
