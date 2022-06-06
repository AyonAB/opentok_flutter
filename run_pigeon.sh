# Run this file to regenerate pigeon files
flutter pub run pigeon \
  --input pigeons/opentok.dart \
  --dart_out lib/opentok.dart \
  --objc_header_out ios/Classes/OpenTok.h \
  --objc_source_out ios/Classes/OpenTok.m \
  --objc_prefix FLT \
  --java_out android/src/main/java/com/natureglobal/opentok_flutter/OpenTok.java \
  --java_package "com.natureglobal.opentok_flutter"