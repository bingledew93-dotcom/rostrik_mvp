# google_mlkit_text_recognition references the optional script-specific
# recognizers (Chinese / Devanagari / Japanese / Korean) from its initialize()
# switch, but the app only bundles the default Latin recognizer — those classes
# aren't on the classpath, so R8 errors on the dangling references in release.
# The branches are never reached at runtime (the OCR scanner only requests
# Latin), so suppressing the warnings is safe.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
