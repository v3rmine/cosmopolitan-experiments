CC:=$(shell if uname -s | grep -q Darwin; then echo x86_64-elf-gcc; else echo gcc; fi)
OBJCOPY:=$(shell if uname -s | grep -q Darwin; then echo x86_64-elf-objcopy; else echo objcopy; fi)
COSMOPOLITAN_DIR:=cosmopolitan

all: dist/hello_c dist/hello_nim dist/hello_rust

dist/hello_c.elf: hello_c.c
	$(CC) -g -Os -static -nostdlib -nostdinc -fno-pie -no-pie -mno-red-zone \
		-fno-omit-frame-pointer -pg \
		-o dist/hello_c.elf hello_c.c -fuse-ld=bfd -Wl,-T,$(COSMOPOLITAN_DIR)/ape.lds \
		-include $(COSMOPOLITAN_DIR)/cosmopolitan.h $(COSMOPOLITAN_DIR)/crt.o \
		$(COSMOPOLITAN_DIR)/ape-no-modify-self.o $(COSMOPOLITAN_DIR)/cosmopolitan.a
dist/hello_c: dist/hello_c.elf
	$(OBJCOPY) -SO binary dist/hello_c.elf dist/hello_c

dist/hello_nim.elf: hello_nim.nim
	nim c --os:linux \
		--cc:gcc \
		--gcc.path:$(shell dirname $(shell which $(CC))) \
		--gcc.exe:$(shell basename $(CC)) \
		--gcc.linkerexe:$(shell basename $(CC)) \
		--gcc.options.linker:"-static" \
		--threads:off \
		-d:cosmLibc \
		--passC:"-I$(COSMOPOLITAN_DIR) -Inim-stubs" \
		--passC:"-static -nostdlib -nostdinc -fno-pie -no-pie -mno-red-zone" \
		--passC:"-include $(COSMOPOLITAN_DIR)/cosmopolitan.h" \
		--passL:"-static -nostdlib -nostdinc -fno-pie -no-pie -mno-red-zone -fuse-ld=bfd" \
		--passL:"-Wl,-T,$(COSMOPOLITAN_DIR)/ape.lds $(COSMOPOLITAN_DIR)/crt.o $(COSMOPOLITAN_DIR)/ape.o $(COSMOPOLITAN_DIR)/cosmopolitan.a" \
		-o:dist/hello_nim.elf \
		-d:release \
		--opt:size \
		-d:danger \
		--mm:arc \
		-d:useMalloc \
		hello_nim.nim
dist/hello_nim: dist/hello_nim.elf
	$(OBJCOPY) -SO binary dist/hello_nim.elf dist/hello_nim

dist/hello_rust.o: hello_rust.rs
	mkdir -p dist
	rustc --emit obj --target=x86_64-unknown-none \
		-Copt-level=s \
		-Clinker=$(shell which $(CC)) -Clink-arg=-Wl,-T,$(COSMOPOLITAN_DIR)/ape.lds -Ctarget-feature=+crt-static \
		hello_rust.rs -o dist/hello_rust.o
dist/hello_rust.elf: dist/hello_rust.o
	$(CC) -g -Os -static -nostdlib -nostdinc -fno-pie -no-pie -mno-red-zone \
		-fno-omit-frame-pointer -pg \
		-o dist/hello_rust.elf dist/hello_rust.o -fuse-ld=bfd -Wl,-T,$(COSMOPOLITAN_DIR)/ape.lds \
		-include $(COSMOPOLITAN_DIR)/cosmopolitan.h $(COSMOPOLITAN_DIR)/crt.o \
		$(COSMOPOLITAN_DIR)/ape-no-modify-self.o $(COSMOPOLITAN_DIR)/cosmopolitan.a
dist/hello_rust: dist/hello_rust.elf
	$(OBJCOPY) -SO binary dist/hello_rust.elf dist/hello_rust

clean:
	rm -rf dist