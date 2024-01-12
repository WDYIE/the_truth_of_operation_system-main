
test2.o:test2.c
		@echo "当前目录：$(shell pwd)"
		gcc -c -o test2.o test2.c
test1.o:test1.c
		@echo "当前目录：$(shell pwd)"
		gcc -c -o test1.o test1.c
test.bin:test1.o test2.o
		gcc -o test.bin test1.o test2.o
all:test.bin
	@echo "compile done"
.PHONY:clean
clean:
	rm ./*.o