#!/usr/bin/env bash

set -eu

pull_cached() {
  echo ":: Pulling cached images for $branch"
  docker-pull-tag "$image_base:$branch-builder" "$image_base:builder" &&
    docker-pull-tag "$image_base:$branch" "$image_base" &&
    return 0

  echo ":: Pulling cached images for master"
  docker-pull-tag "$image_base:master-builder" "$image_base:builder" &&
    docker-pull-tag "$image_base:master" "$image_base" &&
    return 0

  echo ":: Pulling unprefixed cache images"
  docker-pull-tag "$image_base:builder" &&
    docker-pull-tag "$image_base"
}

push_cached() {
  echo ":: Pushing cached images for branch"
  docker-tag-push "$image_base:builder" "$image_base:$branch-builder"
  docker-tag-push "$image_base" "$image_base:$branch"

  echo ":: Pushing unprefixed cached images"
  docker-tag-push "$image_base:builder"
  docker-tag-push "$image_base"
}

image=$1
shift

if [ -z "$image" ]; then
  echo "docker-build-remote-cache <IMAGE> [DOCKER BUILD OPTION...]]" >&2
  exit 64
fi

# img/org.com:foo -> img/org.com
image_base=${image%:*}

# pb/some-branch -> pb-some-branch
branch=${CIRCLE_BRANCH:-""}
branch=${branch:-$(git rev-parse --abbrev-ref HEAD)}
branch=${branch//\//-}

pull_cached || true

# Always push anything we've built on EXIT
trap 'push_cached || true' EXIT

echo ":: Building builder image"
docker build \
  --tag "$image_base:builder" \
  --cache-from "$image_base:builder" \
  --target builder \
  "$@" \
  .

echo ":: Building image"
docker build \
  --tag "$image_base" \
  --cache-from "$image_base:builder" \
  --cache-from "$image_base" \
  "$@" \
  .

echo ":: Pushing final image"
docker-tag-push "$image_base" "$image"

echo ":: Successfuly built image"
sleep 1
exit 0
