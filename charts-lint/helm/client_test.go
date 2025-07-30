package helm

import (
	"bytes"
	"errors"
	"testing"

	"go.uber.org/mock/gomock"
	"helm.sh/helm/v3/pkg/action"
	"helm.sh/helm/v3/pkg/lint/support"
)

var errTest = errors.New("test error")

func TestDependencyUpdate(t *testing.T) {
	controller := gomock.NewController(t)
	mockDep := NewMockdependency(controller)
	mockManager := NewMockmanager(controller)
	mockLinter := NewMocklinter(controller)
	h := New(mockDep, mockManager, mockLinter)

	testcases := []struct {
		name          string
		path          string
		expect        func()
		expectedError error
	}{
		{
			name: "success",
			path: "testPath",
			expect: func() {
				mockDep.EXPECT().List("testPath", gomock.Any()).Return(nil)
				mockManager.EXPECT().Update().Return(nil)
			},
			expectedError: nil,
		},
		{
			name: "no dependency warning",
			path: "testPath",
			expect: func() {
				mockDep.EXPECT().List("testPath", gomock.Any()).Return(nil).Do(func(_ string, buff *bytes.Buffer) {
					buff.WriteString("WARNING: no dependency was found.\n")
				})
			},
			expectedError: nil,
		},
		{
			name: "list error",
			path: "testPath",
			expect: func() {
				mockDep.EXPECT().List("testPath", gomock.Any()).Return(errTest)
			},
			expectedError: errTest,
		},
		{
			name: "update error",
			path: "testPath",
			expect: func() {
				mockDep.EXPECT().List("testPath", gomock.Any()).Return(nil)
				mockManager.EXPECT().Update().Return(errTest)
			},
			expectedError: errTest,
		},
	}

	for _, tc := range testcases {
		t.Run(tc.name, func(t *testing.T) {
			tc.expect()

			err := h.DependencyUpdate(tc.path)
			if !errors.Is(err, tc.expectedError) {
				t.Errorf("expected: %v, got: %v", tc.expectedError, err)
			}
		})
	}
}

func TestDependencyList(t *testing.T) {
	controller := gomock.NewController(t)
	mockDep := NewMockdependency(controller)
	mockManager := NewMockmanager(controller)
	mockLinter := NewMocklinter(controller)
	h := New(mockDep, mockManager, mockLinter)

	testcases := []struct {
		name          string
		path          []string
		expect        func()
		expectedError []error
	}{
		{
			name: "success",
			path: []string{"testPath"},
			expect: func() {
				mockLinter.EXPECT().Run([]string{"testPath"}, nil).Return(&action.LintResult{
					Messages: []support.Message{{}},
				})
			},
			expectedError: nil,
		},
		{
			name: "error message",
			path: []string{"testPath"},
			expect: func() {
				mockLinter.EXPECT().Run([]string{"testPath"}, nil).Return(&action.LintResult{
					Messages: []support.Message{
						{Severity: support.ErrorSev},
					},
				})
			},
			expectedError: []error{errTest},
		},
		{
			name: "warning message",
			path: []string{"testPath"},
			expect: func() {
				mockLinter.EXPECT().Run([]string{"testPath"}, nil).Return(&action.LintResult{
					Messages: []support.Message{
						{Severity: support.WarningSev},
					},
				})
			},
			expectedError: nil,
		},
	}

	for _, tc := range testcases {
		t.Run(tc.name, func(t *testing.T) {
			tc.expect()

			messages := h.Lint(tc.path)

			if len(messages) != len(tc.expectedError) {
				t.Errorf("expected: %v, got: %v", len(tc.expectedError), len(messages))
			}
		})
	}
}
