Pod::Spec.new do |s|
  s.name     = 'RealmConverter'
  s.version  = '0.1.2'
  s.license  =  { :type => 'Apache', :file => 'LICENSE' }
  s.summary  = 'A library that provides the ability to import/export Realm files from a variety of data container formats.'
  s.homepage = 'https://realm.io'
  s.author   = 'Realm'
  s.source   = { :git => 'https://github.com/realm/realm-cocoa-converter.git', :tag => s.version.to_s }
  s.requires_arc = true
  s.platform = :osx, '10.9'
  s.source_files = 'RealmConverter/**/*.{swift,h,m,c}'
  s.dependency 'Realm'
  s.dependency 'PathKit'
  s.dependency 'CSwiftV'
  s.dependency 'TGSpreadsheetWriter'
end
