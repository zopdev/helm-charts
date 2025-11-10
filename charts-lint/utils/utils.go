package utils

import (
	"errors"
	"fmt"
	"os"

	"github.com/google/go-github/v74/github"

	"charts-lint/models"
)

// ErrMissingToken is returned when the GITHUB_TOKEN environment variable is not set.
var ErrMissingToken = errors.New("GITHUB_TOKEN environment variable not set")

// GetGithubClient gets the GitHub client from access token.
func GetGithubClient() (*github.Client, error) {
	token := os.Getenv("GITHUB_TOKEN")
	if token == "" {
		return nil, ErrMissingToken
	}

	return github.NewClient(nil).WithAuthToken(token), nil
}

// Summary prints the summary of helm lint.
func Summary(failedCharts, passedCharts []models.HelmChart) {
	// Passed charts
	if len(passedCharts) > 0 {
		fmt.Printf("\nTOTAL CHARTS UPDATED: %v\n", len(passedCharts)+len(failedCharts))
		fmt.Println("\n===> Charts that passed helm lint:")

		for _, chart := range passedCharts {
			fmt.Printf("-> %s - path: %s\n", chart.Name, chart.Path)
		}
	}

	// Failed charts
	if len(failedCharts) > 0 {
		fmt.Println("\n===> Charts not passing helm lint:")

		for _, chart := range failedCharts {
			fmt.Printf("-> %s - path: %s\n", chart.Name, chart.Path)
		}
	}
}
