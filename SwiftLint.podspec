Pod::Spec.new do |s|
  s.name                      = 'SwiftLint'
  s.version                   = '0.47.0-agoda'
  s.summary                   = 'A tool to enforce Swift style and conventions.'
  s.homepage                  = 'https://github.com/agoda-com/SwiftLint'
  s.license                   = { type: 'MIT', file: 'LICENSE' }
  s.author                    = { 'JP Simard' => 'jp@jpsim.com' }
  s.source                    = { http: "#{s.homepage}/releases/download/#{s.version}/portable_swiftlint.zip" }
  s.preserve_paths            = '*'
  s.exclude_files             = '**/file.zip'
  s.ios.deployment_target     = '9.0'
  s.macos.deployment_target   = '10.10'
  s.tvos.deployment_target    = '9.0'
  s.watchos.deployment_target = '2.0'
end
