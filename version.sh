#!/usr/bin/env bash
set -xeuo pipefail
# semver: 3.4.0

# bump to next major
_VERSION=$(semver bump major  "$(head -1 ./version | tr -d '\n')") && tee <<<"$_VERSION" ./version

# bump to next minor
_VERSION=$(semver bump minor  "$(head -1 ./version | tr -d '\n')") && tee <<<"$_VERSION" ./version

# bump to next patch
_VERSION=$(semver bump patch  "$(head -1 ./version | tr -d '\n')") && tee <<<"$_VERSION" ./version

# bump PRE version
_VERSION=$(semver bump prerel "$(head -1 ./version | tr -d '\n')") && tee <<<"$_VERSION" ./version

# bump PRE version
_VERSION=$(semver bump prerel dev.0 "$(head -1 ./version | tr -d '\n')") && tee <<<"$_VERSION" ./version

git commit -m "Bump version to 'v$(head -1 ./version | tr -d '\n')'" ./version \
&& git tag "v$(head -1 ./version | tr -d '\n')" \
&& git push --atomic origin "$(git rev-parse --abbrev-ref HEAD)" "v$(head -1 ./version | tr -d '\n')"
