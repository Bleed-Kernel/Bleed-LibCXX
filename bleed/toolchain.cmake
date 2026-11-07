set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

set(LLVM_BIN /opt/homebrew/opt/llvm@22/bin)
set(CMAKE_C_COMPILER   ${LLVM_BIN}/clang)
set(CMAKE_CXX_COMPILER ${LLVM_BIN}/clang++)
set(CMAKE_ASM_COMPILER ${LLVM_BIN}/clang)
set(CMAKE_AR           ${LLVM_BIN}/llvm-ar)
set(CMAKE_RANLIB       ${LLVM_BIN}/llvm-ranlib)

set(BLEED_TARGET x86_64-unknown-elf)
set(CMAKE_C_COMPILER_TARGET   ${BLEED_TARGET})
set(CMAKE_CXX_COMPILER_TARGET ${BLEED_TARGET})
set(CMAKE_ASM_COMPILER_TARGET ${BLEED_TARGET})

set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

if(BLEED_PIC)
  set(BLEED_PIC_FLAG -fPIC)
else()
  set(BLEED_PIC_FLAG -fno-pic)
endif()

set(BLEED_FLAGS "-nostdlibinc -isystem ${BLIBC_SYSROOT}/include -D__unix__=1 -D__bleed__=1 ${BLEED_PIC_FLAG} -ffunction-sections -fdata-sections")
set(CMAKE_C_FLAGS_INIT   "${BLEED_FLAGS}")
set(CMAKE_CXX_FLAGS_INIT "${BLEED_FLAGS}")
set(CMAKE_ASM_FLAGS_INIT "${BLEED_FLAGS}")
