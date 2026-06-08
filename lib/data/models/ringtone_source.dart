/// Where an alarm's custom ringtone audio comes from — the discriminator the
/// native playback engine reads to know *how* to interpret an
/// `AppAlarm.customRingtoneUri`.
///
/// Persisted as its `int` [index] in the [AppAlarm] adapter (NOT a registered
/// enum adapter), so the order here is **append-only** — never reorder or
/// remove a value, or existing records re-map to the wrong source.
///   * [classic] — a bundled `res/raw` tone (the default); URI is null and the
///     OS notification channel plays the sound.
///   * [vault]   — a user file copied into app-private storage
///     (`<app-support>/ringtones/`); URI is that durable absolute path, always
///     readable by our own process with no permission.
///   * [system]  — an OS ringtone picked via `RingtoneManager`; URI is a
///     `content://` pointing at system-owned media, readable at fire time via
///     the declared `READ_MEDIA_AUDIO` permission.
enum RingtoneSource { classic, vault, system }
