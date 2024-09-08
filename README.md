# naga_cross

naga_cross is an unofficial native shader cross-compilation library based on the Rust library
[Naga](https://github.com/gfx-rs/wgpu/tree/trunk/naga).
It provides C headers and a config script for use from CMake projects.

As of version 0.1.0, only GLSL to WGSL compilation is made available in naga_cross.


## How to use

Pre-compiled binaries can be found in the [releases list](https://github.com/chrismile/naga_cross/releases).
To use naga_cross in a CMake project, specify the path to naga_crossConfig.cmake in the binary directory as follows.

```shell
cmake -Dnaga_cross_DIR=<dist-dir>/lib/cmake/naga_cross # [...]
```

Then, in CMake, it can be used as follows.

```CMake
find_package(naga_cross REQUIRED)
target_link_libraries(MyTarget PRIVATE naga_cross::static) # can also use naga_cross::shared
```

On the C/C++ side, the functions from the generated C headers can be used, e.g., as follows.

```C++
#include <naga_cross.h>
// [...]
// Setup code and cross-compilation parameters.
const char* glsl_code = "/* ... */ void main() { /* ... */}";
NagaCrossParams params;
NagaCrossShaderDefine shader_defines[2];
shader_defines[0].name = "NUM_LIGHTS";
shader_defines[0].value = "2";
shader_defines[1].name = "USE_LIGHTING";
shader_defines[1].value = nullptr; // define without value
params.shader_stage = NAGA_CROSS_SHADER_STAGE_VERTEX;
params.num_defines = 2;
params.shader_defines = shader_defines;

// Use naga_cross for GLSL -> WGSL cross-compilation.
NagaCrossResult result;
naga_cross_glsl_to_wgsl(glsl_code, &params, &result);
if (result.succeeded) {
    // ... do something with result.wgsl_code ...
} else {
    // ... do something with result.error_string ...
}
naga_cross_release_result(&result);
```


## How to compile

Pre-compiled binaries can be found in the [releases list](https://github.com/chrismile/naga_cross/releases).
If the user wants to compile naga_cross manually, the following command can be used.

```shell
cargo build --lib --release
```

To generate a C header, `cbindgen` needs to be installed via the following command.

```shell
cargo install cbindgen
```

Then, the C header can be generated as follows.

```shell
cbindgen --config cbindgen.toml --crate naga_cross --output naga_cross.h
```
