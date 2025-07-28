package main

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"helm.sh/helm/v3/pkg/action"
	"helm.sh/helm/v3/pkg/cli"
	"helm.sh/helm/v3/pkg/downloader"
	"helm.sh/helm/v3/pkg/getter"
)

// helmChart holds chart name and its path
type helmChart struct {
	name string
	path string
}

// helmDependencyUpdate runs 'helm dependency update' for a given chart path
func helmDependencyUpdate(path string) error {
	dep := action.NewDependency()
	var buff bytes.Buffer
	// runs helm dependency list
	_ = dep.List(path, &buff)

	// early exit for no dependencies warning
	if strings.HasPrefix(buff.String(), "WARNING") {
		return nil
	}

	fmt.Printf("-> Updating dependencies for %v...\n", path)
	settings := cli.New()

	manager := &downloader.Manager{
		Out:              os.Stdout,
		ChartPath:        path,
		Getters:          getter.All(settings),
		RepositoryConfig: settings.RepositoryConfig,
		RepositoryCache:  settings.RepositoryCache,
	}

	if err := manager.Update(); err != nil {
		return fmt.Errorf("failed to update dependencies for %s: %w", path, err)
	}

	fmt.Printf("-> Successfully updated dependencies for %v\n\n", path)

	return nil
}

// helmLint runs 'helm lint' on the given chart paths
func helmLint(paths []string) *action.LintResult {
	fmt.Printf("-> Running lint for %v...\n", paths[0])

	lint := action.NewLint()
	result := lint.Run(paths, nil)

	return result
}

// getDiff returns a list of unique chart names under the 'charts/' directory that have been modified between the base branch and HEAD.
func getDiff() ([]string, error) {
	base := os.Getenv("GITHUB_BASE_REF")

	if base == "" {
		return nil, fmt.Errorf("GITHUB_BASE_REF environment variable not set")
	}

	// run git diff to get differences in base branch and head
	cmd := exec.Command("git", "diff", "--name-only", fmt.Sprintf("origin/%s...HEAD", base))
	cmd.Stderr = os.Stderr
	out, err := cmd.Output()

	if err != nil {
		return nil, err
	}

	changed := strings.Split(string(out), "\n")
	check := make(map[string]bool)
	result := make([]string, 0)

	for _, line := range changed {
		split := strings.Split(line, "/")
		if split[0] == "charts" && len(split) > 1 {
			// Target only paths like charts/<chart>
			dir := split[1]
			if !check[dir] {
				check[dir] = true
				result = append(result, dir)
			}
		}
	}

	return result, nil
}

func main() {
	// Get charts changed in the current PR
	changedCharts, err := getDiff()
	if err != nil {
		fmt.Println(err)
		panic(err)
	}

	// early exit for no updated charts
	if len(changedCharts) == 0 {
		fmt.Println("No charts updated.")
		return
	}

	failedCharts := make([]helmChart, 0)
	passedCharts := make([]helmChart, 0)

	// Process each changed chart
	for _, chart := range changedCharts {
		dir := filepath.Join("charts", chart)

		hc := helmChart{name: chart, path: dir}
		fmt.Printf("\n=== Processing Chart: %s ===\n", chart)

		// Step 1: Update dependencies
		err = helmDependencyUpdate(dir)
		if err != nil {
			failedCharts = append(failedCharts, hc)
			fmt.Println(err)
			continue
		}

		// Step 2: Lint
		result := helmLint([]string{dir})
		if len(result.Errors) > 0 {
			failedCharts = append(failedCharts, hc)
			fmt.Println(result.Messages[0])
		} else {
			passedCharts = append(passedCharts, hc)
			fmt.Printf("OK: Lint succeeded.\n")
		}
	}

	// Final summary
	if len(failedCharts) > 0 {
		fmt.Println("\n=== Charts not passing helm lint:")
		for _, chart := range failedCharts {
			fmt.Printf("-> %s - path: %s\n", chart.name, chart.path)
		}
		os.Exit(1)
	} else {
		fmt.Println("\n=== Charts that passed helm lint:")
		for _, chart := range passedCharts {
			fmt.Printf("-> %s - path: %s\n", chart.name, chart.path)
		}
	}
}
