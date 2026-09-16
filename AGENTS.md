# Agent Instructions

## Language

- Write all project content in English.
- This includes source code, documentation, comments, tests, examples, commit messages, issue text, pull requests, and user-facing strings.
- Keep technical names, API identifiers, and code conventions unchanged when required by external dependencies.

## Documentation Organization

- Store all research, implementation plans, decision records, and work summaries in `wiki/`.
- Keep `wiki/README.md` as the index for wiki documents.
- Use descriptive English filenames and Markdown format for wiki documents.
- Do not place project research, plans, or summaries in the repository root unless a tool or platform requires a root-level file.

## Working Rules

- Read the relevant code and tests before making changes.
- Prefer small, focused changes that match the existing project style.
- Preserve existing user changes and do not revert unrelated work.
- Update tests and documentation when behavior or public APIs change.
- Update `CHANGELOG.md` under `## Unreleased` for every user-visible,
  behavior, compatibility, dependency, workflow, or documentation-policy
  change. Keep the root `# Changelog` title intact because the release
  automation depends on it.
- Run the narrowest relevant validation after each implementation change, then run broader checks when practical.
- Report assumptions, validation results, and any remaining risks in English.

## Flutter and Dart

- Follow the project configuration in `pubspec.yaml` and `analysis_options.yaml`.
- Prefer Flutter and Dart APIs already used by the project before introducing dependencies.
- Keep public APIs documented when adding or changing exported behavior.
