Pod::Spec.new do |s|
  s.name             = 'MidgarSwift'
  s.version          = '0.2.1'
  s.summary          = 'Midgar Swift SDK for Lazy Lantern.'
  s.description      = <<-DESC
  TODO: Add long description of the pod here.
  DESC
  s.homepage         = 'https://github.com/lazylantern/midgar-swift'
  s.license          = { :type => 'Apache', :file => 'LICENSE' }
  s.author           = { 'bastienbeurier' => 'bastienbeurier@gmail.com' }
  s.source           = { :git => 'https://github.com/lazylantern/midgar-swift.git', :tag => s.version.to_s }
  s.ios.deployment_target = '10.0'
  s.source_files = "MidgarSwift/**/*.{swift}"
  s.swift_version = "5.0"
end

