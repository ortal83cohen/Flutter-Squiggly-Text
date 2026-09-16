# pub.dev release pipeline

This repository uses the same two-workflow release model as `flutter_webmcp`.

## What happens on `main`

1. A push to `main` starts `.github/workflows/release.yml`.
2. After `tools/check.sh` passes, `tools/bump_patch_version.sh` increments the
   patch version in `pubspec.yaml` and inserts a dated section in
   `CHANGELOG.md`.
3. The job commits those two files, then pushes the commit and an annotated
   tag named `v{{version}}`.
4. The tag starts `.github/workflows/publish.yml`, which publishes to
   [pub.dev](https://pub.dev/packages/flutter_squiggly_text) with a short-lived
   GitHub OpenID Connect token.

The bump commit message starts with `chore(release): v`. That prefix is the
loop guard: the same job does not bump again when GitHub delivers that commit
back as a `main` push.

## First version

Automated publishing on pub.dev can be enabled only after a package already
exists. Version `0.1.0` is therefore published once from a local machine with
`flutter pub publish`. Later patch versions are produced by the workflows.

`.pubignore` keeps `tools/`, `wiki/`, tests, and CI files out of the uploaded
archive so the pub.dev layout warning for a plural `tools` directory does not
apply to the published package.

## Operator gates

These are not files in the repository:

1. A repository secret named `RELEASE_GITHUB_TOKEN` with contents write
   access. The default `GITHUB_TOKEN` cannot start `publish.yml`.
2. Branch protection on `main` must allow that token to push.
3. On the pub.dev admin tab for `flutter_squiggly_text`, enable GitHub Actions
   publishing for `ortal83cohen/Flutter-Squiggly-Text` with tag pattern
   `v{{version}}`.
