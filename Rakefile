task :install do
  sh 'yes | gem uninstall ut'
  sh 'gem build ut.gemspec'
  sh 'gem install ut-*.gem'
  sh 'rm ut-*.gem'

  if `which rbenv`.length > 0
    sh 'rbenv rehash'
  end
end

