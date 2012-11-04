JAR_NAME = 'cities'

desc 'Builds all .java files in java_src, putting the compiled .class files in java_classes.'
task :java do
  outdated_sources = Dir.glob('java_src/*.java').reject do |java_file|
    uptodate?(
      'java_classes/' + File.basename(java_file, '.java') + '.class',
      java_file
    )
  end
  puts 'Compiling'
  if system 'javac ' + outdated_sources.join(' ') + ' -d java_classes -classpath "jar/*"'
    puts 'Jarring'
    class_files = Dir.glob('java_classes/**/*.class').collect do |path|
      path.sub!('java_classes', '')
      path = ' -C java_classes ' + path
    end.join(' ')
    system 'jar cf jar/' + JAR_NAME + '.jar ' + class_files
  end
end