#!/bin/bash

# ===== CONFIG =====
GITHUB_ORG="your-github-org"
GITHUB_TOKEN="ghp_xxxxxxxxx"

GITLAB_URL="http://your-gitlab-domain"
GITLAB_TOKEN="glpat-xxxxxxxx"
GITLAB_GROUP_ID="2"   # numeric GitLab group ID

WORKDIR="/tmp/github-migrate"
mkdir -p $WORKDIR
cd $WORKDIR

echo "Getting repo list from GitHub..."

curl -s -H "Authorization: token $GITHUB_TOKEN" \
https://api.github.com/orgs/$GITHUB_ORG/repos?per_page=200 \
| jq -r '.[].name' > repos.txt

while read REPO
do
  echo "========== Processing $REPO =========="

  # Create project in GitLab
  curl -s --request POST \
    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --data "name=$REPO&namespace_id=$GITLAB_GROUP_ID" \
    $GITLAB_URL/api/v4/projects

  # Clone from GitHub
  git clone --mirror https://$GITHUB_TOKEN@github.com/$GITHUB_ORG/$REPO.git

  cd $REPO.git

  # Push to GitLab
  git remote add gitlab $GITLAB_URL/github-backup/$REPO.git
  git push --mirror gitlab

  cd ..
  rm -rf $REPO.git

done < repos.txt

echo "Completed."
