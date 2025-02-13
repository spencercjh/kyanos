#!/usr/bin/env bash
. $(dirname "$0")/common.sh
set -ex

CMD="$1"
DOCKER_REGISTRY="$2"
FILE_PREFIX="/tmp/kyanos"
LNAME="${FILE_PREFIX}_containerd_filter_by_container_id.log"

function test_containerd_filter_by_container_id() {
    if [ -z "$DOCKER_REGISTRY" ]; then 
        IMAGE_NAME="busybox:1"
    else
        IMAGE_NAME=$DOCKER_REGISTRY"/busybox:1"
    fi
    nerdctl pull "$IMAGE_NAME"
    nerdctl container prune -f

    cid1=$(nerdctl run -d "$IMAGE_NAME" sh -c 'sleep 10; wget -T 10 http://www.baidu.com')
    export cid1
    echo $cid1

    cid2=$(nerdctl run -d "$IMAGE_NAME" sh -c 'sleep 11; wget -T 10 http://example.com')
    export cid2
    echo $cid2

    timeout 30 ${CMD} watch --debug-output http --container-id=${cid1} 2>&1 | tee "${LNAME}" &
    sleep 10
    wait

    cat "${LNAME}"
    check_patterns_in_file "${LNAME}" "baidu.com"
    check_patterns_not_in_file "${LNAME}" "example.com"
}

function main() {
    test_containerd_filter_by_container_id
}

main
