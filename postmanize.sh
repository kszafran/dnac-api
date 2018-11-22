#!/bin/bash

set -e

tempdir=$(mktemp -d)

# sandbox credentials
user='devnetuser'
pass='Cisco123!'

cookie=$(curl -s -D - 'https://sandboxdnac.cisco.com/api/system/v1/identitymgmt/login' \
    -H "Authorization: Basic $(echo -n "$user:$pass" | base64)" \
    | grep -i set-cookie | awk '{print $2}' | tr -d '\r')

ids=$(curl -s 'https://sandboxdnac.cisco.com/api/dnacaap/v1/dnacaap-app-services/consumer-portal/release-catalog/artifact?type=api' \
    -H "Cookie: $cookie" \
    --compressed | jq -r '.[].id')

for id in $ids; do
    echo "Downloading $id"
    curl -s "https://sandboxdnac.cisco.com/api/dnacaap/v1/dnacaap-app-services/consumer-portal/release-catalog/artifact/$id?type=api" \
    -H "Cookie: $cookie" \
    --compressed > "$tempdir/$id.json"
done

jq . -s "$tempdir"/*.json > api-eft.json
rm -rf "$tempdir"

curl 'https://pubhub.devnetcloud.com/media/dna-center-api-126/docs/swagger_dnacp_126.json' \
    --compressed > api-ga.json

function summarize() {
  jq -r '..|.request? | select(.) | .method + (.method | (7 - length) * " ") + (.url.raw | gsub(".*}}"; ""))' "$1" > "$2"
}

coll=DNA-C_Platform_Intent_API_v1.2_EFT.postman_collection.json
jq -f postmanize-eft.jq api-eft.json | jq -s '.[0].item = [.[1]] + .[0].item | .[0]' - auth.json > $coll
summarize "$coll" overview-eft.txt

coll=DNA-C_Platform_Intent_API_v1.2.6_GA.postman_collection.json
jq -f postmanize-ga.jq api-ga.json > $coll
summarize "$coll" overview-ga.txt