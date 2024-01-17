YAML_FILE="zenhub_api.yml"

repos=($(yq eval '.repos[]' "$YAML_FILE"))
token=($(yq eval '.github-token' "$YAML_FILE"))

myGithubRepos=()
myGithubIds=()

for repo in "${repos[@]}"; do
    API_ENDPOINT="https://api.github.com/repos/${repo}"
    response=$(curl -s -H "Authorization: token $token" "$API_ENDPOINT")
    repository_id=$(echo "$response" | jq -r '.id')
    IFS=' ' read -r id name <<< "$API_ENDPOINT"
    echo -e "\n레포지토리: $repo"
    read -n 1 -p "이 레포지토리를 추가하시겠습니까?: (y/n) " input
    if [ "$input" == "y" ]; then
                myGithubIds+=("$repository_id")
        myGithubRepos+=("$repo")
        echo "   ✅"
    else
        echo "   ❌"
    fi
done

for index in "${!myGithubIds[@]}"; do
    ./pipeline.sh "${myGithubIds[index]}" "${myGithubRepos[index]}"
done