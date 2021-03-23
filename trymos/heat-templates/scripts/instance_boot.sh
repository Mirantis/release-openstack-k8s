#!/bin/bash
set -x

export PUBLIC_INTERFACE=$private_floating_interface
export NODE_METADATA=$node_metadata
export DOCKER_EE_URL=$docker_ee_url
export DOCKER_EE_RELEASE=$docker_ee_release
export DOCKER_UCP_IMAGE=$docker_ucp_image
export UCP_DOCKER_SWARM_DATA_PORT=$docker_ucp_swarm_data_port
export DOCKER_DEFAULT_ADDRESS_POOL=$docker_default_address_pool

function wait_condition_send {
    local status=${1:-SUCCESS}
    local reason=${2:-\"empty\"}
    local data=${3:-\"empty\"}
    local data_binary="{\"status\": \"$status\", \"reason\": \"$reason\", \"data\": $data}"
    echo "Trying to send signal to wait condition 5 times: $data_binary"
    WAIT_CONDITION_NOTIFY_EXIT_CODE=2
    i=0
    while (( ${WAIT_CONDITION_NOTIFY_EXIT_CODE} != 0 && ${i} < 5 )); do
        $wait_condition_notify -k --data-binary "$data_binary" && WAIT_CONDITION_NOTIFY_EXIT_CODE=0 || WAIT_CONDITION_NOTIFY_EXIT_CODE=2
        i=$((i + 1))
        sleep 1
    done
    if (( ${WAIT_CONDITION_NOTIFY_EXIT_CODE} !=0 && "${status}" == "SUCCESS" ))
    then
        status="FAILURE"
        reason="Can't reach metadata service to report about SUCCESS."
    fi
    if [ "$status" == "FAILURE" ]; then
        exit 1
    fi
}

bash /usr/share/trymos/launch.sh

if [[ "$?" == "0" ]]; then
    wait_condition_send "SUCCESS" "Deploying TryMOS successfuly ."
else
    wait_condition_send "FAILURE" "Deploying TryMOS failed."
fi
