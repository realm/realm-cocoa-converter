platform :osx, '10.9'
use_frameworks!

target 'RealmConverter' do
    pod 'Realm'
    pod 'PathKit', '~> 0.6.0' # 0.7+ requires swift 3
    pod 'CSwiftV'
    pod 'TGSpreadsheetWriter'

    target 'RealmConverterTests' do
    	inherit! :search_paths
  	end
end
