Pod::Spec.new do |s|
  s.name          = "mjCamera"
  s.version       = "0.0.1"
  s.summary       = "A simple camera library"
  s.homepage      = "https://github.com/blackho1e/mjCamera"
  s.license       = { :type => "MIT", :file => "LICENSE" }
  s.author        = { "Minju Kang" => "blackdole@naver.com" }
  s.source        = { :git => "https://github.com/blackho1e/mjCamera.git", :tag => s.version.to_s }
  s.platform      = :ios, '8.0'
  s.requires_arc  = true
  s.source_files  = 'Classes/**/*.swift'
  s.resources     = ['Classes/Assets.xcassets', 'Classes/**/*.xib']

  s.subspec 'Localization' do |t|
    %w|en ko|.map {|localename|
      t.subspec localename do |u|
        u.ios.resources = "Classes/#{localename}.lproj"
        u.ios.preserve_paths = "Classes/#{localename}.lproj"
     end
    }
  end

end