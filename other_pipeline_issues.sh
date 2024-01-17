#!/bin/bash

if [ "$#" -ne 3 ]; then
    exit 1
fi

# Your GraphQL API endpoint
API_ENDPOINT="https://api.zenhub.com/public/graphql"

TOKEN=($(yq eval '.zenhub-token' "$YAML_FILE"))

PIPELINE_ID=$1

repositoryGhId=$2 

repositoryName=$3

# Your GraphQL query
QUERY='
query ($pipelineId: ID!, $filters: IssueSearchFiltersInput!, $after: String) {
  searchIssuesByPipeline(pipelineId: $pipelineId, filters: $filters, after: $after) {
    totalCount
    pageInfo {
      endCursor
      hasNextPage
    }
    edges {
      cursor
      node {
        title
        labels {
          totalCount
          nodes {
            name
          }
        }
        state
      }
    }
  }
}
'


# Your filters
FILTERS='{
  "repositoryGhIds": '$repositoryGhId',
  "labels": {
    "in": "QA"
  }
}'


while true; do
    # Make the GraphQL API request with Authorization header and after cursor
    response=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d "{\"query\":\"$QUERY\",\"variables\":{\"pipelineId\":\"$PIPELINE_ID\",\"filters\":$FILTERS}}" $API_ENDPOINT)

    # Extracting titles and labels from the GraphQL response and appending to CSV
    jq -r --arg repositoryName $repositoryName '.data.searchIssuesByPipeline.edges[] | [$repositoryName, .node.title,.node.state,.node.labels.nodes[].name] | @csv' <<< "$response" >> $PIPELINE_ID.csv

    # Update the cursor for the next iteration
    after_cursor=$(jq -r '.data.searchIssuesByPipeline.pageInfo.endCursor' <<< "$response")

    printf '\xEF\xBB\xBF' | cat - $PIPELINE_ID.csv >> issues_encoded.csv

    # Check if there is more data
    has_next_page=$(jq -r '.data.searchIssuesByPipeline.pageInfo.hasNextPage' <<< "$response")
    if [ "$has_next_page" == "false" ]; then
        break
    fi
done

rm ./$PIPELINE_ID.csv
