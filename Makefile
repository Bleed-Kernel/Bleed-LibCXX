LLVM_VER    = 22.1.8
LLVM_REPO   = https://github.com/llvm/llvm-project.git
LLVM_SRC    = external/llvm-project

BLIBC_DIR  ?= $(if $(wildcard ../blibc/include/bleed),../blibc,external/blibc)
BLIBC_REPO  = https://github.com/Bleed-Kernel/blibc.git

BUILD       = build
BLIBC_SYSROOT_DIR = $(abspath $(BLIBC_DIR))/sysroot
BUILD_PIC   = build-pic
LLVM_BIN    = /opt/homebrew/opt/llvm@22/bin
SYSROOT     = sysroot

CMAKE_FLAGS = \
	-G Ninja \
	-DCMAKE_TOOLCHAIN_FILE=$(CURDIR)/bleed/toolchain.cmake \
	-DBLIBC_SYSROOT=$(abspath $(BLIBC_DIR))/sysroot \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_PREFIX=$(CURDIR)/$(SYSROOT) \
	-DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind" \
	-DLLVM_INCLUDE_TESTS=OFF \
	-DLIBCXX_INCLUDE_TESTS=OFF \
	-DLIBCXX_INCLUDE_BENCHMARKS=OFF \
	-DLIBCXX_INCLUDE_DOCS=OFF \
	-DLIBCXXABI_INCLUDE_TESTS=OFF \
	-DLIBUNWIND_INCLUDE_TESTS=OFF \
	-DLIBUNWIND_INCLUDE_DOCS=OFF \
	-DLIBCXX_ENABLE_SHARED=OFF \
	-DLIBCXXABI_ENABLE_SHARED=OFF \
	-DLIBUNWIND_ENABLE_SHARED=OFF \
	-DLIBCXX_CXX_ABI=libcxxabi \
	-DLIBCXXABI_USE_LLVM_UNWINDER=ON \
	-DLIBCXXABI_ENABLE_STATIC_UNWINDER=ON \
	-DLIBCXXABI_USE_COMPILER_RT=OFF \
	-DLIBCXX_USE_COMPILER_RT=OFF \
	-DLIBUNWIND_USE_COMPILER_RT=OFF \
	-DLIBCXX_ENABLE_THREADS=ON \
	-DLIBCXXABI_ENABLE_THREADS=ON \
	-DLIBUNWIND_ENABLE_THREADS=ON \
	-DLIBCXX_HAS_PTHREAD_API=ON \
	-DLIBCXXABI_HAS_PTHREAD_API=ON \
	-DLIBCXX_ENABLE_LOCALIZATION=ON \
	-DLIBCXX_ENABLE_WIDE_CHARACTERS=ON \
	-DLIBCXX_ENABLE_FILESYSTEM=ON \
	-DLIBCXX_ENABLE_RANDOM_DEVICE=ON \
	-DLIBCXX_ENABLE_TIME_ZONE_DATABASE=OFF \
	-DLIBCXX_ENABLE_MONOTONIC_CLOCK=ON \
	-DLIBCXX_HAS_MUSL_LIBC=OFF \
	-DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=OFF \
	-DLIBCXX_SHARED_OUTPUT_NAME=c++_shared_unused \
	-DLIBCXXABI_SHARED_OUTPUT_NAME=c++abi_shared_unused \
	-DLIBUNWIND_SHARED_OUTPUT_NAME=unwind_shared_unused

.PHONY: all source blibc configure clean distclean

all: $(SYSROOT)/lib/libc++.a $(SYSROOT)/lib/libc++.so $(SYSROOT)/lib/libclang_rt.builtins-x86_64.a

source: $(LLVM_SRC)/runtimes/CMakeLists.txt

$(LLVM_SRC)/runtimes/CMakeLists.txt:
	@mkdir -p external
	git clone --depth 1 --branch llvmorg-$(LLVM_VER) --filter=blob:none --sparse $(LLVM_REPO) $(LLVM_SRC)
	cd $(LLVM_SRC) && git sparse-checkout set runtimes libcxx libcxxabi libunwind cmake llvm/cmake llvm/utils/llvm-lit third-party/benchmark libc compiler-rt
	sh bleed/patch-libcxx.sh $(LLVM_SRC)

blibc:
	@if [ ! -d "$(BLIBC_DIR)" ]; then git clone $(BLIBC_REPO) $(BLIBC_DIR); fi
	@$(MAKE) -C $(BLIBC_DIR) --no-print-directory

$(BUILD)/build.ninja: source blibc bleed/toolchain.cmake bleed/patch-libcxx.sh Makefile
	sh bleed/patch-libcxx.sh $(LLVM_SRC)
	cmake $(CMAKE_FLAGS) -S $(LLVM_SRC)/runtimes -B $(BUILD)

configure: $(BUILD)/build.ninja

$(SYSROOT)/lib/libc++.a: $(BUILD)/build.ninja
	ninja -C $(BUILD) install-cxx install-cxxabi install-unwind

UNWIND_OBJS = libunwind.cpp.obj Unwind-EHABI.cpp.obj Unwind-seh.cpp.obj UnwindLevel1.c.obj \
	UnwindLevel1-gcc-ext.c.obj Unwind-sjlj.c.obj Unwind-wasm.c.obj UnwindRegistersRestore.S.obj \
	UnwindRegistersSave.S.obj

$(BUILD_PIC)/build.ninja: $(BUILD)/build.ninja
	cmake $(CMAKE_FLAGS) -DBLEED_PIC=ON -S $(LLVM_SRC)/runtimes -B $(BUILD_PIC)

$(SYSROOT)/lib/libc++.so: $(BUILD_PIC)/build.ninja $(SYSROOT)/lib/libc++.a
	ninja -C $(BUILD_PIC) cxx_static cxxabi_static
	cp $(BUILD_PIC)/lib/libc++.a $(BUILD_PIC)/libcxx-only.a
	$(LLVM_BIN)/llvm-ar d $(BUILD_PIC)/libcxx-only.a $(UNWIND_OBJS)
	x86_64-elf-gcc -nostdlib -m64 -Wl,-shared -Wl,-soname,libc++.so -Wl,--eh-frame-hdr -Wl,--no-undefined \
		-Wl,-z,noexecstack -o $@ $(BLIBC_SYSROOT_DIR)/lib/crtdso.o \
		-Wl,--whole-archive $(BUILD_PIC)/libcxx-only.a $(BUILD_PIC)/lib/libc++abi.a -Wl,--no-whole-archive \
		$(BLIBC_SYSROOT_DIR)/lib/libc.so -lgcc

BUILD_RT = build-builtins

$(BUILD_RT)/build.ninja: $(BUILD)/build.ninja
	cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE=$(CURDIR)/bleed/toolchain.cmake -DBLIBC_SYSROOT=$(BLIBC_SYSROOT_DIR) \
		-DBLEED_PIC=ON -DCMAKE_BUILD_TYPE=Release -DCOMPILER_RT_BAREMETAL_BUILD=ON \
		-DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON -DCOMPILER_RT_BUILD_BUILTINS=ON -DCOMPILER_RT_BUILTINS_HIDE_SYMBOLS=ON \
		-DLLVM_CMAKE_DIR=$(CURDIR)/$(LLVM_SRC)/llvm/cmake/modules \
		-S $(LLVM_SRC)/compiler-rt/lib/builtins -B $(BUILD_RT)

$(SYSROOT)/lib/libclang_rt.builtins-x86_64.a: $(BUILD_RT)/build.ninja
	ninja -C $(BUILD_RT)
	@mkdir -p $(SYSROOT)/lib
	cp $(BUILD_RT)/lib/generic/libclang_rt.builtins-x86_64.a $@

clean:
	rm -rf $(BUILD) $(BUILD_PIC) $(BUILD_RT) $(SYSROOT)

distclean: clean
	rm -rf external
