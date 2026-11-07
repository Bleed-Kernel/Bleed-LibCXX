LIBCXX_DIR ?= $(if $(wildcard ../Bleed-LibCXX/Makefile),../Bleed-LibCXX,external/Bleed-LibCXX)
LLVM_BIN   ?= /opt/homebrew/opt/llvm@22/bin

BLEED_CXX = $(LLVM_BIN)/clang++
BLEED_CC  = $(LLVM_BIN)/clang
BLEED_LD  = x86_64-elf-gcc

BLEED_CXXFLAGS = \
	--target=x86_64-unknown-elf \
	-nostdlibinc \
	-isystem $(LIBCXX_DIR)/sysroot/include/c++/v1 \
	-isystem $(LIBCXX_DIR)/sysroot/include \
	-isystem $(SYSROOT)/include \
	-D__unix__=1 \
	-D__bleed__=1 \
	-fno-pic \
	-std=c++23

BLEED_CXX_LDFLAGS = -static -nostdlib -no-pie -Wl,--eh-frame-hdr

BLEED_CXX_LIBS = \
	-Wl,--start-group \
	$(LIBCXX_DIR)/sysroot/lib/libc++.a \
	$(LIBCXX_DIR)/sysroot/lib/libc++abi.a \
	$(LIBCXX_DIR)/sysroot/lib/libunwind.a \
	$(SYSROOT)/lib/blibc.a \
	-lgcc \
	-Wl,--end-group

BLEED_CXX_PIC = -fPIC

BLEED_LIBCXX_SO = $(LIBCXX_DIR)/sysroot/lib/libc++.so

BLEED_CXX_DYN_LDFLAGS = -nostdlib -no-pie -Wl,-dynamic-linker,/lib/libc.so -Wl,--eh-frame-hdr
BLEED_CXX_SO_LDFLAGS  = -nostdlib -Wl,-shared -Wl,--eh-frame-hdr

BLEED_CXX_DYN_LIBS = $(BLEED_LIBCXX_SO) $(SYSROOT)/lib/libc.so -lgcc
