Pod::Spec.new do |s|
  s.name           = 'SwiftLint'
  s.version        = '0.13.2'
  s.summary        = 'A tool to enforce Swift style and conventions.'
  s.homepage       = 'https://github.com/realm/SwiftLint'
  s.license        = 'MIT'
  s.author         = { 'JP Simard' => 'jp@jpsim.com' }
  s.source         = { :http => "#{s.homepage}/releases/download/#{s.version}/portable_swiftlint.zip" }
  s.preserve_paths = '*'
end
