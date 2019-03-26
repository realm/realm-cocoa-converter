use_frameworks!

target 'RealmConverterMacOS' do
    platform :osx, '10.9'
    pod 'Realm', '~> 3.8.0'
    pod 'PathKit'
    # Using a fork until this PR is merged https://github.com/Daniel1of1/CSwiftV/pull/40
    pod 'CSwiftV', :git => 'https://github.com/farktronix/CSwiftV.git', :branch => 'Swift5'
    pod 'TGSpreadsheetWriter'

    target 'RealmConverterTests' do
    	inherit! :search_paths
  	end
end

target 'RealmConverteriOS' do
    platform :ios, '10.0'
    pod 'Realm', '~> 3.8.0'
    pod 'PathKit'
    # Using a fork until this PR is merged https://github.com/Daniel1of1/CSwiftV/pull/40
    pod 'CSwiftV', :git => 'https://github.com/farktronix/CSwiftV.git', :branch => 'Swift5'
end
