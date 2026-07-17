# KGMusic patch

This directory vendors `just_audio 0.10.6` because its
`LockCachingAudioSource` reads `Accept-Ranges` through `HttpHeaders.value()`.
That API throws when KuGou CDN responses contain the header more than once.

KGMusic changes only the range-support check to inspect all header values.
Remove this vendored dependency once an upstream release includes the same
fix, then restore the hosted dependency in the root `pubspec.yaml`.
