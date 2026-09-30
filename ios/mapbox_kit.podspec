Pod::Spec.new do |s|
  s.name             = 'mapbox_kit'
  s.version          = '0.1.0'
  s.summary          = 'Mapbox maps for DartNative: MapView over FFI.'
  s.description      = <<-DESC
Native side of mapbox_kit for iOS: hosts a Mapbox MapView through the
DartNative plugin view system and exposes camera, style, annotation and
location APIs to Dart as C entry points.
                       DESC
  s.homepage         = 'https://github.com/edkluivert/mapbox_kit'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Kluivert' => 'team@funkash.com' }
  s.source           = { :path => '.' }

  s.source_files     = 'Classes/**/*.swift'
  s.swift_version    = '5.9'
  s.platform         = :ios, '15.0'

  s.dependency 'MapboxMaps', '11.31.0'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
end
