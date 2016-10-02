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

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '2.3'
    end
  end
end
