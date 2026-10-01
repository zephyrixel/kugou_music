# KGMusic patches

This directory vendors `just_audio 0.10.6` for two `LockCachingAudioSource` fixes:

- Inspect all `Accept-Ranges` values because KuGou CDN responses can repeat the
  header and `HttpHeaders.value()` rejects that response.
- Report 100% download progress only after the sink is closed and the partial
  file has been renamed. Forward download failures to the progress stream and
  release the sink/client, so cache cleanup cannot mistake buffered bytes for a
  completed file or retain a failed transfer indefinitely.

Regression tests live in `test/audio_cache_test.dart`. Replace this vendored
package with a hosted release only when it contains both behaviors.
