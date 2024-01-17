#!/bin/bash
# -*- coding:en_KR.utf-8 -*-

# GraphQL API endpoint
API_ENDPOINT="https://api.zenhub.com/public/graphql"

YAML_FILE="zenhub_api.yml"

TOKEN=($(yq eval '.zenhub-token' "$YAML_FILE"))

if [ "$#" -ne 2 ]; then
    exit 1
fi

repositoryGhId=$1 

repositoryName=$2

# GraphQL query
QUERY='
query SearchClosedIssues(
    $workspaceId: ID!
    $filters: IssueSearchFiltersInput!
    $after: String
) {
    searchClosedIssues(
        workspaceId: $workspaceId
        filters: $filters
        after: $after
    ) {
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

# Input data
WORKSPACE_ID="63760304e748fd2e030bd2da"
FILTERS='
{
    "repositoryGhIds": '$repositoryGhId',
    "labels" : {
        "in" : "QA"
    }
}
'


after_cursor=""

while true; do
    # Make the GraphQL API request with Authorization header and after cursor
    response=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d "{\"query\":\"$QUERY\",\"variables\":{\"workspaceId\":\"$WORKSPACE_ID\",\"filters\":$FILTERS,\"after\":\"$after_cursor\"}}" $API_ENDPOINT)

    # Extracting titles and labels from the GraphQL response and appending to CSV
    jq -r --arg repositoryName "$repositoryName" '.data.searchClosedIssues.edges[] |[$repositoryName, .node.title,.node.state,.node.labels.nodes[].name] | @csv' <<< "$response" > closed_issues.csv

    # Update the cursor for the next iteration
    after_cursor=$(jq -r '.data.searchClosedIssues.pageInfo.endCursor' <<< "$response")

    printf '\xEF\xBB\xBF' | cat - closed_issues.csv >> issues_encoded.csv

    # Check if there is more data
    has_next_page=$(jq -r '.data.searchClosedIssues.pageInfo.hasNextPage' <<< "$response")
    if [ "$has_next_page" == "false" ]; then
        break
    fi
done

rm ./closed_issues.csv