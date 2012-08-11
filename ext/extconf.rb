require "mkmf"
$CFLAGS << " -fobjc-gc -framework Cocoa -framework IOKit "
create_makefile("IdleTime")
