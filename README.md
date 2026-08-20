# rbrownwsws/commit-signed-by-github-app

This action commits all staged files using the GitHub API.
If a GitHub App Installation Token is used for authentication, the commit will be signed by the GitHub App.

> ### Warning
>
> This action is only intended to make a single commit on the current branch and will not update your local repository.
>
> It will not work if you try to check out a different branch or repository.
>
> It will try to make a single commit with all the changes between the currently staged files and $GITHUB_SHA.
> Any intermediate commits you make locally will be ignored.
>
> You cannot call this action multiple times in a single workflow run.

