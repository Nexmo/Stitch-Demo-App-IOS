source 'git@github.com:CocoaPods/Specs.git'
source 'git@github.com:Vonage/NexmoCocoaPodSpecs.git'


target 'Stitch-Demo' do
	use_frameworks!
    pod 'Nexmo-Stitch'
	pod 'StitchObjC', :git => 'https://github.com/Vonage/stitch_iOS.git', :branch => 'develop'
	pod 'SwiftyJSON', '~> 4.0'
	pod 'MBProgressHUD', '~> 1.1.0'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
