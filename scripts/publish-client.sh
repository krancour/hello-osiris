#!/usr/bin/env bash

# AVOID INVOKING THIS SCRIPT DIRECTLY -- USE `make publish-client`

set -euxo pipefail

ghr -t ${GITHUB_TOKEN} -u ${GITHUB_PROJECT_USERNAME} -r ${GITHUB_PROJECT_REPONAME} -c ${GIT_FULL_SHA} -delete ${REL_VERSION} ./bin/
