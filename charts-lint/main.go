package main

import (
	"fmt"
	"os"
	"path/filepath"

	"helm.sh/helm/v3/pkg/action"
	"helm.sh/helm/v3/pkg/cli"
	"helm.sh/helm/v3/pkg/downloader"
	"helm.sh/helm/v3/pkg/getter"

	githubpkg "charts-lint/github"
	helmpkg "charts-lint/helm"
	"charts-lint/models"
	"charts-lint/utils"
)

func main() {
	// get client for GitHub
	c, err := utils.GetGithubClient()
	if err != nil {
		panic(err)
	}

	client := githubpkg.New(c.PullRequests)

	// Get charts changed in the current PR
	changedCharts, err := client.GetDiff()
	if err != nil {
		panic(err)
	}

	// early exit for no updated charts
	if len(changedCharts) == 0 {
		fmt.Println("No charts updated.")
		return
	}

	failedCharts := make([]models.HelmChart, 0)
	passedCharts := make([]models.HelmChart, 0)

	// Process each changed chart
	for _, chart := range changedCharts {
		dir := filepath.Join("charts", chart)

		dep := action.NewDependency()
		settings := cli.New()
		manager := &downloader.Manager{
			Out:              os.Stdout,
			ChartPath:        dir,
			Getters:          getter.All(settings),
			RepositoryConfig: settings.RepositoryConfig,
			RepositoryCache:  settings.RepositoryCache,
		}
		lint := action.NewLint()

		// helm client
		helm := helmpkg.New(dep, manager, lint)

		hc := models.HelmChart{Name: chart, Path: dir}
		fmt.Printf("\n=== Processing Chart: %s ===\n", chart)

		// Step 1: Update dependencies
		err = helm.DependencyUpdate(dir)
		if err != nil {
			failedCharts = append(failedCharts, hc)

			fmt.Println(err)

			continue
		}

		// Step 2: Lint
		errorMessages := helm.Lint([]string{dir})
		if len(errorMessages) == 0 {
			passedCharts = append(passedCharts, hc)

			fmt.Printf("OK: Lint succeeded.\n")
		} else {
			failedCharts = append(failedCharts, hc)

			for _, err = range errorMessages {
				fmt.Println(err)
			}
		}
	}

	// Final summary
	utils.Summary(failedCharts, passedCharts)

	if len(failedCharts) > 0 {
		os.Exit(1)
	}
}
