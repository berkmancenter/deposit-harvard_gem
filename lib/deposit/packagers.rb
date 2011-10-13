class Deposit::Packagers
end

# load Packagers sub-classes
Dir[File.dirname(__FILE__) + '/packagers/*.rb'].each {|file| require file }
