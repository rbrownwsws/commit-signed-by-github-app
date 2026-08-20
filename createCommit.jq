{
  query: $query,
  variables: {
    repo: $repo,
    branch: $branch,
    expectedHeadOid: $expectedHeadOid,
    commitMessage: $commitMessage,
    fileChanges: {
      additions: $additions,
      deletions: $deletions
    }
  }
}
