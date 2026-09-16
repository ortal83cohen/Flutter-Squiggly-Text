# Linux CI Dependencies

## Summary

The platform compatibility workflow now installs the Linux desktop build
packages before running the Linux example build on GitHub Actions.

## Reason

The Linux matrix job failed during `flutter build linux --debug` because CMake
could not find the required `gtk+-3.0` package. The fix installs Flutter's
standard Linux desktop build dependencies on `ubuntu-latest` for the Linux
target only.

## Validation

The failing GitHub Actions log showed the missing package before build file
generation:

```text
The following required packages were not found:

- gtk+-3.0
```

The local change is limited to workflow setup and should be validated by
rerunning the platform compatibility workflow on GitHub Actions.
