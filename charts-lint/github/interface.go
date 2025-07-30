package github

import (
	"context"

	gh "github.com/google/go-github/v74/github"
)

// pullRequest defines method for retrieving files in a pull request from GitHub.
type pullRequest interface {
	ListFiles(ctx context.Context, owner, repo string, number int, opts *gh.ListOptions) ([]*gh.CommitFile, *gh.Response, error)
}
