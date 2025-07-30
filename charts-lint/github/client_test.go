package github

import (
	"errors"
	"strconv"
	"testing"

	"github.com/google/go-github/v74/github"
	"go.uber.org/mock/gomock"
)

var errTest = errors.New("test error")

func TestGithubClient_GetDiff(t *testing.T) {
	controller := gomock.NewController(t)
	mockPullRequest := NewMockPullRequest(controller)

	c := New(mockPullRequest)

	testcases := []struct {
		name           string
		expect         func()
		expectedOutput []string
		expectErr      error
	}{
		{
			name: "success",
			expect: func() {
				t.Setenv("REPOSITORY_OWNER", "test")
				t.Setenv("REPOSITORY_NAME", "test/test")
				t.Setenv("PR_NUMBER", "1")
				chart := "charts/test"

				mockPullRequest.EXPECT().
					ListFiles(gomock.Any(), "test", "test", 1, nil).
					Return([]*github.CommitFile{
						{Filename: &chart},
					}, nil, nil)
			},
			expectedOutput: []string{"test"},
			expectErr:      nil,
		},
		{
			name: "ListFiles error",
			expect: func() {
				t.Setenv("REPOSITORY_OWNER", "test")
				t.Setenv("REPOSITORY_NAME", "test/test")
				t.Setenv("PR_NUMBER", "1")
				chart := "charts/test"

				mockPullRequest.EXPECT().
					ListFiles(gomock.Any(), "test", "test", 1, nil).
					Return([]*github.CommitFile{
						{Filename: &chart},
					}, nil, errTest)
			},
			expectedOutput: nil,
			expectErr:      errTest,
		},
		{
			name: "strconv error",
			expect: func() {
				t.Setenv("REPOSITORY_OWNER", "test")
				t.Setenv("REPOSITORY_NAME", "test/test")
				t.Setenv("PR_NUMBER", "abc")
			},
			expectedOutput: nil,
			expectErr:      strconv.ErrSyntax,
		},
	}

	for _, tc := range testcases {
		t.Run(tc.name, func(t *testing.T) {
			tc.expect()

			charts, err := c.GetDiff()

			if !errors.Is(err, tc.expectErr) {
				t.Errorf("GetDiff() error = %v, wantErr %v", err, tc.expectErr)
			}

			if len(charts) != len(tc.expectedOutput) {
				t.Errorf("len(charts) = %v, want %v", len(charts), len(tc.expectedOutput))
			}
		})
	}
}
