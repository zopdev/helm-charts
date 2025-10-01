package github

import (
	"context"
	"os"
	"strconv"
	"strings"
)

// githubClient provides methods to interact with GitHub pull requests.
type githubClient struct {
	pr pullRequest
}

// New returns a new githubClient using the provided PullRequest interface.
func New(pr pullRequest) *githubClient {
	return &githubClient{pr: pr}
}

// GetDiff returns unique chart names changed in the pull request.
func (c *githubClient) GetDiff() ([]string, error) {
	// Get env variables for github repo
	owner := os.Getenv("REPOSITORY_OWNER")
	repoPath := os.Getenv("REPOSITORY_NAME")
	repo := strings.Split(repoPath, "/")[1]

	prNumber, err := strconv.Atoi(os.Getenv("PR_NUMBER"))
	if err != nil {
		return nil, err
	}

	// get changes in the pull request
	commitFiles, _, err := c.pr.ListFiles(context.Background(), owner, repo, prNumber, nil)
	if err != nil {
		return nil, err
	}

	charts := make([]string, 0)
	check := make(map[string]bool)

	// extract charts from pull request changes
	for _, file := range commitFiles {
		name := file.GetFilename()

		split := strings.Split(name, "/")
		if split[0] == "charts" && len(split) > 1 {
			// Target only paths like charts/<chart>
			chart := split[1]
			if !check[chart] {
				check[chart] = true

				charts = append(charts, chart)
			}
		}
	}

	return charts, nil
}
