require 'mkmf'

case RUBY_PLATFORM
  when /linux/
    if have_library('bluetooth')
      create_makefile('mindset_device')
    end
end

