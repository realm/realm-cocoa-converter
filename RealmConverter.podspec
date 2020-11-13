Pod::Spec.new do |s|
  s.name     = 'RealmConverter'
  s.version  = '0.5.4'
  s.license  =  { :type => 'Apache-2.0', :file => 'LICENSE' }
  s.summary  = 'A library that provides the ability to import/export Realm files from a variety of data container formats.'
  s.homepage = 'https://realm.io'
  s.author   = { 'Realm' => 'help@realm.io' }
  s.source   = { :git => 'https://github.com/realm/realm-cocoa-converter.git', :tag => s.version.to_s }
  s.requires_arc = true

  s.osx.deployment_target = '10.9'
  s.ios.deployment_target = '10.0'
  s.swift_version = '5.0'

  s.source_files = 'RealmConverter/**/*.{swift,h,m,c}'

  s.dependency 'Realm'
  s.dependency 'PathKit'
  s.dependency 'CSwiftV'
  s.dependency 'SSZipArchive'
  s.osx.dependency 'TGSpreadsheetWriter'

  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
end
