package utils

import (
	"bytes"
	"errors"
	"io"
	"os"
	"strings"
	"testing"

	"charts-lint/models"
)

func TestGetGithubClient(t *testing.T) {
	testcases := []struct {
		name        string
		setEnv      func()
		expectedErr error
	}{
		{
			name: "Github Token Not Set",
			setEnv: func() {
			},
			expectedErr: ErrMissingToken,
		},
		{
			name: "Github Token Set",
			setEnv: func() {
				t.Setenv("GITHUB_TOKEN", "test-token")
			},
			expectedErr: nil,
		},
	}

	for _, tc := range testcases {
		t.Run(tc.name, func(t *testing.T) {
			tc.setEnv()

			_, err := GetGithubClient()
			if !errors.Is(err, tc.expectedErr) {
				t.Errorf("GetGithubClient() error = %v, wantErr %v", err, tc.expectedErr)
			}
		})
	}
}

func TestSummary(t *testing.T) {
	testcases := []struct {
		name   string
		failed []models.HelmChart
		passed []models.HelmChart
	}{
		{
			name: "TestSummary",
			failed: []models.HelmChart{
				{Name: "test", Path: "fail/test"},
			},
			passed: []models.HelmChart{
				{Name: "test", Path: "pass/test"},
			},
		},
	}

	for _, tc := range testcases {
		t.Run(tc.name, func(t *testing.T) {
			originalStdout := os.Stdout

			r, w, err := os.Pipe()
			if err != nil {
				t.Fatalf("Error creating pipe: %v", err)
			}

			os.Stdout = w
			defer func() {
				os.Stdout = originalStdout

				_ = r.Close()
			}()

			Summary(tc.failed, tc.passed)

			_ = w.Close()

			var buf bytes.Buffer
			if _, err := io.Copy(&buf, r); err != nil {
				t.Fatalf("Error reading stdout: %v", err)
			}

			output := buf.String()
			if !strings.Contains(output, "fail/test") {
				t.Errorf("Expected output to include 'fail/test', got: %s", output)
			}

			if !strings.Contains(output, "pass/test") {
				t.Errorf("Expected output to include 'pass/test', got: %s", output)
			}
		})
	}
}
