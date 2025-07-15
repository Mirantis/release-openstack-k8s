#!/bin/bash
set -x

INVENTORY_PATH="/srv/trymosk/rockoon/virtual_lab/ansible/inventory"

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

if [[ -f "${INVENTORY_PATH}/ansible_overrides.yaml" ]]; then
    curl --retry 6 --retry-delay 5 -L https://binary-dev-kaas-virtual.mcp.mirantis.com/openstack/bin/utils/yq/yq-v3.3.2 -o /usr/bin/yq
    chmod +x /usr/bin/yq

    cd ${INVENTORY_PATH}
    yq merge ansible_overrides.yaml trymosk_single_node.yaml > trymosk_single_node.merged
    mv trymosk_single_node.merged trymosk_single_node.yaml
fi

bash /srv/trymosk/launch.sh

if [[ "$?" == "0" ]]; then
    wait_condition_send "SUCCESS" "Deploying TryMOSK successfuly ."
else
    wait_condition_send "FAILURE" "Deploying TryMOSK failed."
fi
