Pod::Spec.new do |s|
  s.name     = 'RealmConverter'
  s.version  = '0.5.1'
  s.license  =  { :type => 'Apache-2.0', :file => 'LICENSE' }
  s.summary  = 'A library that provides the ability to import/export Realm files from a variety of data container formats.'
  s.homepage = 'https://realm.io'
  s.author   = { 'Realm' => 'help@realm.io' }
  s.source   = { :git => 'https://github.com/realm/realm-cocoa-converter.git', :tag => s.version.to_s }
  s.requires_arc = true

  s.osx.deployment_target = '10.9'
  s.ios.deployment_target = '10.0'

  s.source_files = 'RealmConverter/**/*.{swift,h,m,c}'

  s.dependency 'Realm', '~> 3.8.0'
  s.dependency 'PathKit'
  s.dependency 'CSwiftV'
  s.dependency 'SSZipArchive'
  s.osx.dependency 'TGSpreadsheetWriter'
end
