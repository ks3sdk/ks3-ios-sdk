Pod::Spec.new do |s|

  s.name         = "Ks3SDK"
  s.version      = "2.1.3"
  s.summary      = "iOS SDK for Kingsoft Standard Storage Service"

  s.description  = <<-DESC
    An iOS SDK for developers to use Kingsoft Standard Storage Service easier.
                   DESC

  s.homepage     = "https://github.com/ks3sdk/ks3-ios-sdk"

  s.license      = "Apache License, Version 2.0"

  s.author       = { "voidmain" => "voidmain1313113@gmail.com" }

  s.source       = { :git => "https://github.com/ks3sdk/ks3-ios-sdk.git", :tag => "v#{s.version}" }

  s.requires_arc = true

  s.ios.deployment_target = '7.0'

  s.source_files  = "KS3YunSDK/**/*.{h,m}"
end
