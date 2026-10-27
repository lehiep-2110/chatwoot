require 'json'
require 'digest'

revision, source = ARGV
abort 'Usage: verify_easyhire_image.rb REVISION SOURCE_DIRECTORY' unless revision && source
abort 'Wrong source revision' unless File.read('/app/.git_sha').strip == revision

paths = %w[app enterprise lib config db docker/entrypoints].flat_map do |directory|
  Dir.glob(File.join(source, directory, '**', '*'), File::FNM_DOTMATCH).select { |file| File.file?(file) }
end
paths.concat(%w[Gemfile Gemfile.lock package.json pnpm-lock.yaml LICENSE enterprise/LICENSE].map { |file| File.join(source, file) })
paths.select! { |file| File.file?(file) }
paths.each do |file|
  relative = file.delete_prefix("#{source}/")
  target = File.join('/app', relative)
  abort "Missing source: #{relative}" unless File.file?(target)
  expected = File.binread(file).gsub("\r\n", "\n")
  actual = File.binread(target).gsub("\r\n", "\n")
  abort "Source mismatch: #{relative}" unless Digest::SHA256.hexdigest(actual) == Digest::SHA256.hexdigest(expected)
end

%w[.git .codex .agents .env .env.example node_modules spec].each do |entry|
  abort "Unexpected local artifact: #{entry}" if File.exist?(File.join('/app', entry))
end

manifest = JSON.parse(File.read('/app/public/vite/.vite/manifest.json'))
asset_manifest = JSON.parse(File.read('/app/public/vite/.vite/manifest-assets.json'))
abort 'Empty production manifest' if manifest.empty?
assets = (manifest.values + asset_manifest.values).flat_map do |entry|
  [entry.fetch('file'), *entry.fetch('css', []), *entry.fetch('assets', [])]
end.uniq
assets.each do |asset|
  target = File.join('/app/public/vite', asset)
  abort "Missing production asset: #{asset}" unless File.file?(target) && File.size(target).positive?
end
abort 'Missing widget SDK' unless File.file?('/app/public/packs/js/sdk.js')

scripts = Dir.glob('/app/docker/entrypoints/**/*.{sh,rb}')
scripts.each do |file|
  abort "Invalid Linux entrypoint: #{file}" unless File.executable?(file) && !File.binread(file).include?("\r\n")
  interpreter = file.end_with?('.sh') ? ['sh', '-n', file] : ['ruby', '-c', file]
  abort "Invalid entrypoint syntax: #{file}" unless system(*interpreter, out: File::NULL)
end
puts JSON.generate(status: 'PASS', revision: revision, source_files: paths.length, assets: assets.length, entrypoints: scripts.length)
