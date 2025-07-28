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

type failedChart struct {
	name string
	path string
}

func helmDependencyUpdate(path string) error {
	dep := action.NewDependency()
	var buff bytes.Buffer
	_ = dep.List(path, &buff)

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

func helmLint(paths []string) *action.LintResult {
	fmt.Printf("-> Running lint for %v...\n", paths[0])

	lint := action.NewLint()
	result := lint.Run(paths, nil)

	return result
}

func getDiff() ([]string, error) {
	base := os.Getenv("GITHUB_BASE_REF")

	if base == "" {
		return nil, fmt.Errorf("GITHUB_BASE_REF environment variable not set")
	}

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
		if split[0] == "charts" {
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
	changedCharts, err := getDiff()
	if err != nil {
		fmt.Println(err)
		panic(err)
	}

	failedCharts := make([]failedChart, 0)

	for _, chart := range changedCharts {
		dir := filepath.Join("charts", chart)
		fmt.Printf("\n=== Processing Chart: %s ===\n", chart)

		err = helmDependencyUpdate(dir)
		if err != nil {
			failedCharts = append(failedCharts, failedChart{
				name: chart,
				path: dir,
			})
			fmt.Println(err)
		}

		result := helmLint([]string{dir})

		if len(result.Errors) > 0 {
			failedCharts = append(failedCharts, failedChart{
				name: chart,
				path: dir,
			})
			fmt.Println(result.Messages[0])
		} else {
			fmt.Printf("OK: Lint succeeded.\n")
		}
	}

	if len(failedCharts) > 0 {
		fmt.Println("\n=== Failed Charts:")
		for _, chart := range failedCharts {
			fmt.Printf("-> %s - path: %s\n", chart.name, chart.path)
		}
		os.Exit(1)
	} else {
		fmt.Println("\n=== Successfully Lint Charts:")
	}
}
