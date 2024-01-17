#!/bin/bash

if [ "$#" -ne 2 ]; then
    exit 1
fi

repositoryGhId=$1 
repositoryName=$2

# GraphQL API endpoint
API_ENDPOINT="https://api.zenhub.com/public/graphql"

YAML_FILE="zenhub_api.yml"

TOKEN=($(yq eval '.zenhub-token' "$YAML_FILE"))

# Your GraphQL query
QUERY='
query getPipelinesForWorkspace($workspaceId: ID!) {
  workspace(id: $workspaceId) {
    id
    pipelinesConnection(first: 50) {
      nodes {
        id
        name
      }
    }
  }
}
'

echo '
------------------------------------------
현재 레포지토리 : '"$repositoryName"'
------------------------------------------
'

# Your workspace ID
WORKSPACE_ID="63760304e748fd2e030bd2da"

# Execute the GraphQL query using curl
response=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d "{\"query\":\"$QUERY\",\"variables\":{\"workspaceId\":\"$WORKSPACE_ID\"}}" $API_ENDPOINT)

pipeline_info=$(jq -r '.data.workspace.pipelinesConnection.nodes | map("\(.id) \(.name)") | join(";")' <<< "$response")

myPipelineIds=()

IFS=';' read -ra pipelines <<< "$pipeline_info"
for pipeline in "${pipelines[@]}"; do
  IFS=' ' read -r id name <<< "$pipeline"
  # Now, you can use $id and $name as needed
  echo -e "\nName: $name"
  read -n 1 -p "이 파이프 라인을 추가하시겠습니까?: (y/n) " input
  if [ "$input" == "y" ]; then
    myPipelineIds+=("$id")
    echo "   ✅"
  else
    echo "   ❌"
  fi
done
echo -e "\nName: closed"
read -n 1 -p "이 파이프 라인을 추가하시겠습니까?: (y/n) " input
if [ "$input" == "y" ]; then
  echo "   ✅"
  echo -e "\n"
  ./closed_issues.sh $repositoryGhId $repositoryName
  else
  echo "   ❌"
  echo -e "\n"
fi

for pipeline in "${myPipelineIds[@]}"; do
  ./other_pipeline_issues.sh $pipeline $repositoryGhId $repositoryName
done
