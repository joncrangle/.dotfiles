---
name: de-test
description: Debloat the test suite for a project.
---

# De-test

Perform a comprehensive, global evaluation of all test files across the entire codebase to eliminate test bloat and structural redundancy.

Execute these cleanup steps across all directories:

1. **Identify Redundant Suites:** Find separate test files that target the same module, service, or overlapping component boundaries, and plan to merge them.
2. **Test Theatere** Identify tests that do not deliver defect detection or regression protection. Mark these for deletion.
3. **Flag Tautological & Implementation Tests:** Locate tests that merely verify internal implementation details, assert that an internal function was called (over-mocking), or duplicate source logic in assertions. Mark these for deletion.
4. **Consolidate Micro-tests:** Group scattered, fine-grained unit tests into unified, behavior-driven integration tests focused on critical business outcomes.
5. **Prune Edge-Case Overlap:** Eliminate redundant edge-case variations if a broader, parameterized test or a single robust sad-path test already covers the logic branch.

Do not execute any deletions yet. Provide a comprehensive audit report listing:

- **Files to be completely deleted** (with a 1-sentence reason for each)
- **Files to be consolidated/merged** (showing what goes where)
- **Estimated reduction** in total test count and file count

Wait for my explicit approval before modifying the codebase.
