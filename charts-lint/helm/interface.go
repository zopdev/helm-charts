package helm

import (
	"io"

	"helm.sh/helm/v3/pkg/action"
)

// dependency defines method for listing Helm chart dependencies.
type dependency interface {
	List(string, io.Writer) error
}

// manager defines method for updating Helm chart dependencies.
type manager interface {
	Update() error
}

// linter defines method for linting Helm charts.
type linter interface {
	Run(paths []string, vals map[string]any) *action.LintResult
}
