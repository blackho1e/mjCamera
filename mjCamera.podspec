Pod::Spec.new do |s|
  s.name          = "mjCamera"
  s.version       = "0.0.7"
  s.summary       = "A simple camera library"
  s.homepage      = "https://github.com/blackho1e/mjCamera"
  s.license       = { :type => "MIT", :file => "LICENSE" }
  s.author        = { "Minju Kang" => "blackdole@naver.com" }
  s.source        = { :git => "https://github.com/blackho1e/mjCamera.git", :tag => s.version.to_s }
  s.platform      = :ios, '8.0'
  s.requires_arc  = true
  s.source_files  = 'Classes/**/*.swift'
  s.resources     = ['Classes/Assets.xcassets', 'Classes/**/*.xib', 'Classes/*.lproj']
end
