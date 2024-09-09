# BSD 2-Clause License
#
# Copyright (c) 2024, Christoph Neuhauser
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

get_filename_component(_IMPORT_PREFIX "${CMAKE_CURRENT_LIST_FILE}" PATH)
get_filename_component(_IMPORT_PREFIX "${_IMPORT_PREFIX}" PATH)
get_filename_component(_IMPORT_PREFIX "${_IMPORT_PREFIX}" PATH)
get_filename_component(_IMPORT_PREFIX "${_IMPORT_PREFIX}" PATH)

set(naga_cross_VERSION 0.1.0)

add_library(naga_cross::static STATIC IMPORTED GLOBAL)
add_library(naga_cross::shared SHARED IMPORTED GLOBAL)

#target_include_directories(naga_cross::static INTERFACE "${_IMPORT_PREFIX}/include")
#target_include_directories(naga_cross::shared INTERFACE "${_IMPORT_PREFIX}/include")
set_target_properties(naga_cross::static PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include"
)
set_target_properties(naga_cross::shared PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include"
)

if (EMSCRIPTEN)
    set_target_properties(naga_cross::static PROPERTIES
        IMPORTED_LOCATION "${_IMPORT_PREFIX}/lib/libnaga_cross.a"
    )
    set_target_properties(naga_cross::shared PROPERTIES
        IMPORTED_LOCATION "${_IMPORT_PREFIX}/lib/naga_cross.wasm"
    )
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set_target_properties(naga_cross::static PROPERTIES
        IMPORTED_LOCATION "${_IMPORT_PREFIX}/lib/libnaga_cross.a"
    )
    set_target_properties(naga_cross::shared PROPERTIES
        IMPORTED_LOCATION "${_IMPORT_PREFIX}/lib/libnaga_cross.so"
        IMPORTED_NO_SONAME TRUE
    )
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    if(EXISTS "${_IMPORT_PREFIX}/lib/naga_cross.lib")
        # MSVC
        set_target_properties(naga_cross::static PROPERTIES
            IMPORTED_LOCATION "${_IMPORT_PREFIX}/lib/naga_cross.lib"
            IMPORTED_IMPLIB "${_IMPORT_PREFIX}/lib/naga_cross.lib"
        )
    else()
        # E.g., MinGW
        set_target_properties(naga_cross::static PROPERTIES
            IMPORTED_LOCATION "${_IMPORT_PREFIX}/lib/libnaga_cross.a"
        )
    endif()
    set_target_properties(naga_cross::shared PROPERTIES
        IMPORTED_LOCATION "${_IMPORT_PREFIX}/bin/libnaga_cross.dll"
    )
    # If we don't add some library dependencies for Rust, we get lots of errors of the form:
    # "[...]/library\std\src\sys\pal\windows/net.rs:39:(.text+0x1840): undefined reference to `WSAStartup'"
    target_link_libraries(naga_cross::static INTERFACE ws2_32)
    target_link_libraries(naga_cross::shared INTERFACE ws2_32)
    # "[...]/library\std\src\sys\pal\windows/c.rs:275:(.text+0x3e302): undefined reference to `NtReadFile'"
    target_link_libraries(naga_cross::static INTERFACE ntdll)
    target_link_libraries(naga_cross::shared INTERFACE ntdll)
    # "[...]/library\std\src\sys\pal\windows/os.rs:331:(.text+0x21523): undefined reference to `GetUserProfileDirectoryW'"
    target_link_libraries(naga_cross::static INTERFACE userenv)
    target_link_libraries(naga_cross::shared INTERFACE userenv)
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    set_target_properties(naga_cross::static PROPERTIES
        IMPORTED_LOCATION "${_IMPORT_PREFIX}/lib/libnaga_cross.a"
    )
    set_target_properties(naga_cross::shared PROPERTIES
        IMPORTED_LOCATION "${_IMPORT_PREFIX}/lib/libnaga_cross.dylib"
    )
else()
    message(FATAL_ERROR "System currently not supported by naga_cross.")
endif()
