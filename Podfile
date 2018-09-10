use_frameworks!

target 'RealmConverterMacOS' do
    platform :osx, '10.9'
    pod 'Realm', '~> 3.8.0'
    pod 'PathKit'
    # This fork of CSwiftV has Swift 4 support. Once PR https://github.com/Daniel1of1/CSwiftV/pull/38 is merged this can be changed back to the main repository
    pod 'CSwiftV', :git => "https://github.com/UberJason/CSwiftV.git" 
    pod 'TGSpreadsheetWriter'

    target 'RealmConverterTests' do
    	inherit! :search_paths
  	end
end

target 'RealmConverteriOS' do
    platform :ios, '10.0'
    pod 'Realm', '~> 3.8.0'
    pod 'PathKit'
    # This fork of CSwiftV has Swift 4 support. Once PR https://github.com/Daniel1of1/CSwiftV/pull/38 is merged this can be changed back to the main repository
    pod 'CSwiftV', :git => "https://github.com/UberJason/CSwiftV.git"
end
