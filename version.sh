#!/usr/bin/env bash
set -xeuo pipefail
# semver: 3.4.0

# bump to next major
semver bump major  "$(head -1 ./version | tr -d '\n')" | tee ./version

# bump to next minor
semver bump minor  "$(head -1 ./version | tr -d '\n')" | tee ./version

# bump to next patch
semver bump patch  "$(head -1 ./version | tr -d '\n')" | tee ./version

# bump PRE version
semver bump prerel "$(head -1 ./version | tr -d '\n')" | tee ./version

git commit -m "Bump version to 'v$(head -1 ./version | tr -d '\n')'" ./version \
&& git tag "v$(head -1 ./version | tr -d '\n')" \
&& git push --atomic origin "$(git rev-parse --abbrev-ref HEAD)" "v$(head -1 ./version | tr -d '\n')"
