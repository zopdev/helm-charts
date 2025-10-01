package helm

import (
	"bytes"
	"fmt"
	"strings"

	"helm.sh/helm/v3/pkg/action"
	"helm.sh/helm/v3/pkg/lint/support"
)

// helmClient provides methods to execute helm commands like dependency update and linting
// using injected dependency, manager and linter interfaces.
type helmClient struct {
	dep     dependency
	manager manager
	lint    linter
}

// New returns a new helmClient with the provided dependency, manager, and linter.
func New(dep dependency, manager manager, lint linter) *helmClient {
	return &helmClient{dep: dep, manager: manager, lint: lint}
}

// DependencyUpdate runs 'helm dependency update' for a given chart path.
func (h *helmClient) DependencyUpdate(path string) error {
	var buff bytes.Buffer
	// runs helm dependency list
	err := h.dep.List(path, &buff)
	if err != nil {
		return err
	}

	// early exit for no dependencies warning
	if strings.HasPrefix(buff.String(), "WARNING") {
		return nil
	}

	fmt.Printf("-> Updating dependencies for %v...\n", path)

	// runs helm dependency update
	if err = h.manager.Update(); err != nil {
		return fmt.Errorf("failed to update dependencies for %s: %w", path, err)
	}

	fmt.Printf("-> Successfully updated dependencies for %v\n\n", path)

	return nil
}

// Lint runs 'helm lint' on the given chart paths.
func (h *helmClient) Lint(paths []string) []error {
	fmt.Printf("-> Running lint for %v...\n", paths[0])

	result := h.lint.Run(paths, nil)

	// early exit if no Warning or Error
	if !action.HasWarningsOrErrors(result) {
		return nil
	}

	errors := make([]error, 0)

	for _, msg := range result.Messages {
		if msg.Severity == support.ErrorSev {
			errors = append(errors, msg)
		} else if msg.Severity == support.WarningSev {
			fmt.Println(msg)
		}
	}

	return errors
}
