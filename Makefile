CC:=$(shell if uname -s | grep -q Darwin; then echo x86_64-elf-gcc; else echo gcc; fi)
OBJCOPY:=$(shell if uname -s | grep -q Darwin; then echo x86_64-elf-objcopy; else echo objcopy; fi)
COSMOPOLITAN_DIR:=cosmopolitan-v1.0

all: dist/hello_c dist/hello_nim dist/hello_rust

dist/hello_c.elf: hello_c.c
	mkdir -p dist
	$(CC) -g -Os -static -nostdlib -nostdinc -fno-pie -no-pie -mno-red-zone \
		-fno-omit-frame-pointer -pg \
		-o dist/hello_c.elf hello_c.c -fuse-ld=bfd -Wl,-T,$(COSMOPOLITAN_DIR)/ape.lds \
		-include $(COSMOPOLITAN_DIR)/cosmopolitan.h $(COSMOPOLITAN_DIR)/crt.o \
		$(COSMOPOLITAN_DIR)/ape-no-modify-self.o $(COSMOPOLITAN_DIR)/cosmopolitan.a
dist/hello_c: dist/hello_c.elf
	$(OBJCOPY) -SO binary dist/hello_c.elf dist/hello_c

dist/hello_nim.elf: hello_nim.nim
	mkdir -p dist
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
		-Ctarget-feature=+crt-static \
		hello_rust.rs -o dist/hello_rust.o
dist/hello_rust.elf: dist/hello_rust.o
	$(CC) -g -Os -static -nostdlib -nostdinc -fno-pie -no-pie -mno-red-zone \
		-fno-omit-frame-pointer -pg \
		-o dist/hello_rust.elf dist/hello_rust.o -fuse-ld=bfd -Wl,-T,$(COSMOPOLITAN_DIR)/ape.lds \
		-include $(COSMOPOLITAN_DIR)/cosmopolitan.h $(COSMOPOLITAN_DIR)/crt.o \
		$(COSMOPOLITAN_DIR)/ape-no-modify-self.o $(COSMOPOLITAN_DIR)/cosmopolitan.a
dist/hello_rust: dist/hello_rust.elf
	$(OBJCOPY) -SO binary dist/hello_rust.elf dist/hello_rust

# NOTE: Std Rust => stuck because of https://github.com/jart/cosmopolitan/issues/180
# https://medium.com/@squanderingtime/manually-linking-rust-binaries-to-support-out-of-tree-llvm-passes-8776b1d037a4
# DEV ONLY x86_64-unknown-linux-musl | x86_64-apple-darwin
# TARGET=x86_64-unknown-linux-musl
# LLVM_HOME:=$(shell if uname -s | grep -q Darwin; then echo /usr/local/Cellar/llvm/$(shell ls /usr/local/Cellar/llvm | head -n1)/bin; else echo UNSUPPORTED; exit 1; fi)
# TOOLCHAIN_LIB:=$(shell rustc --print target-libdir --target=$(TARGET))
# dist/hello_rust_std*.{ll,bc}: hello_rust_std.rs
# 	mkdir -p dist
# 	rustc -g -O --emit llvm-ir --target=$(TARGET) \
# 		-Cpanic=abort \
# 		-Cno-redzone=yes \
# 		-Csave-temps --out-dir dist \
# 		-Copt-level=s \
# 		-Ctarget-feature=+crt-static \
# 		hello_rust_std.rs
# 	rm dist/*no-opt*
# dist/hello_rust_std*.o: dist/hello_rust_std*.{ll,bc}
# 	find dist -name '*.bc' | xargs -I{} -n 1 $(LLVM_HOME)/opt -o {} {}
# 	find dist -name '*.bc' | xargs -n 1 $(LLVM_HOME)/llc -filetype=obj

## BEGIN LINK RUST MANUALLY
# dist/hello_rust_std: dist/hello_rust_std*.o
# 	$(LLVM_HOME)/clang -m64 \
# 		dist/*.o \
# 		-Wl,-dead_strip -nodefaultlibs -lSystem -lresolv -lc -lm \
# 		 \
# 		$(shell find $(TOOLCHAIN_LIB) -name '*.rlib')
## END LINK RUST MANUALLY

# dist/hello_rust_std.elf: dist/hello_rust_std*.o
# 	$(LLVM_HOME)/clang -m64 --target=$(TARGET) \
# 		-g -Os -static -nostdlib -fno-pie -mno-red-zone \
# 		-fno-omit-frame-pointer \
# 		dist/*.o -fuse-ld=lld -Wl,-T,cosmopolitan-v0.2/ape.lds \
# 		-include cosmopolitan-v0.2/cosmopolitan.h cosmopolitan-v0.2/crt.o \
# 		cosmopolitan-v0.2/ape.o cosmopolitan-v0.2/cosmopolitan.a \
# 		-o dist/hello_rust_std.elf \
# 		$(shell find $(TOOLCHAIN_LIB) -name '*.rlib')

clean:
	rm -rf dist