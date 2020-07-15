#!/usr/bin/env bash
eval $(kubectl -n openstack get secret neutron-etc -ojson | jq -r '.data["metadata_agent.ini"]' | base64 -d | grep metadata | grep = | tr -d ' ')
kubectl -n openstack-tf-shared patch secret tf-data --patch "{\"data\": {\"nova_metadata_host\": \"$(echo $nova_metadata_host | base64)\", \"nova_metadata_port\": \"$(echo $nova_metadata_port | base64)\", \"metadata_proxy_secret\": \"$(echo $metadata_proxy_shared_secret | base64)\"}}"
