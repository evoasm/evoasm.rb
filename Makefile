all:
	rake compile
clean:
	rake clean
debug:
	rake compile -- --enable-debug
