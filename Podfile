def shared_pods 
    pod 'Realm'
    pod 'PathKit'
    pod 'CSwiftV'
end

target 'RealmConverterMacOS' do
    use_frameworks!
    platform :osx, '10.9'
    shared_pods
    pod 'TGSpreadsheetWriter'

    target 'RealmConverterTestsMacOS' do
        inherit! :search_paths
    end
end

target 'RealmConverteriOS' do
    use_frameworks!
    platform :ios, '10.0'
    shared_pods

    target 'RealmConverterTestsiOS' do
        inherit! :search_paths
    end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '10.0'
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '10.9'
    end
  end
end
