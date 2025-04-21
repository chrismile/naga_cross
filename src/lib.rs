// BSD 2-Clause License
//
// Copyright (c) 2024-2025, Christoph Neuhauser
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer.
//
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

use std::ffi::CString;
use std::{ffi::CStr, ffi::c_int, os::raw::c_char};
use naga;
use naga::{FastHashMap, ShaderStage};

#[repr(C)]
pub enum NagaCrossShaderStage {
    Vertex, Fragment, Compute
}

#[repr(C)]
pub struct NagaCrossShaderDefine {
    name: *const c_char,
    value: *const c_char,
}

#[repr(C)]
pub struct NagaCrossParams {
    shader_stage: NagaCrossShaderStage,
    num_defines: c_int,
    shader_defines: *const NagaCrossShaderDefine,
}

#[repr(C)]
pub struct NagaCrossResult {
    succeeded: bool,
    wgsl_code: *mut c_char,
    error_string: *mut c_char,
}

/// Converts the passed GLSL code to WGSL code.
#[no_mangle]
pub unsafe extern "C" fn naga_cross_glsl_to_wgsl(
    glsl_code: *const c_char, params: *const NagaCrossParams, result: *mut NagaCrossResult) {
    assert!(!glsl_code.is_null());
    assert!(!result.is_null());
    assert!(!params.is_null());
    // See: https://doc.rust-lang.org/std/ffi/struct.CString.html#method.into_raw
    let glsl_string = CStr::from_ptr(glsl_code).to_str().unwrap();

    let shader_stage = match (*params).shader_stage {
        NagaCrossShaderStage::Vertex => ShaderStage::Vertex,
        NagaCrossShaderStage::Fragment => ShaderStage::Fragment,
        NagaCrossShaderStage::Compute => ShaderStage::Compute,
    };

    let defines = &mut FastHashMap::default();
    for i in 0..(*params).num_defines {
        assert!(!glsl_code.is_null());
        let shader_define = (*params).shader_defines.wrapping_add(usize::try_from(i).unwrap());
        assert!(!(*shader_define).name.is_null());
        let name = CStr::from_ptr((*shader_define).name).to_str().unwrap().to_string();
        let value = match (*shader_define).value.is_null() {
            true => "",
            false => CStr::from_ptr((*shader_define).value).to_str().unwrap()
        }.to_string();
        defines.insert(name, value);
    }

    let mut frontend = naga::front::glsl::Frontend::default();
    let options = naga::front::glsl::Options{ stage: shader_stage, defines: defines.clone() };
    let module_opt = frontend.parse(&options, &glsl_string);
    if module_opt.is_err() {
        (*result).succeeded = false;
        (*result).error_string = CString::into_raw(CString::new(module_opt.unwrap_err().emit_to_string(&glsl_string)).unwrap());
        return;
    }
    let module = module_opt.unwrap();

    let module_info_opt = naga::valid::Validator::new(
        naga::valid::ValidationFlags::all(),
        naga::valid::Capabilities::all(),
    ).validate(&module);
    if module_info_opt.is_err() {
        (*result).succeeded = false;
        (*result).error_string = CString::into_raw(CString::new(module_info_opt.unwrap_err().emit_to_string(&glsl_string)).unwrap());
        return;
    }
    let module_info = module_info_opt.unwrap();

    let wgsl_code_opt = naga::back::wgsl::write_string(
        &module, &module_info, naga::back::wgsl::WriterFlags::empty());
    if wgsl_code_opt.is_err() {
        (*result).succeeded = false;
        (*result).error_string = CString::into_raw(CString::new(wgsl_code_opt.unwrap_err().to_string()).unwrap());
        return;
    }

    (*result).succeeded = true;
    (*result).wgsl_code = CString::into_raw(CString::new(wgsl_code_opt.unwrap()).unwrap());
}

/// Frees result struct provided by @see naga_cross_glsl_to_wgsl.
#[no_mangle]
pub unsafe extern "C" fn naga_cross_release_result(result: *mut NagaCrossResult) {
    assert!(!result.is_null());
    // See: https://doc.rust-lang.org/std/ffi/struct.CString.html#method.from_raw
    if (*result).succeeded {
        assert!(!(*result).wgsl_code.is_null());
        let _ = CString::from_raw((*result).wgsl_code);
    } else {
        assert!(!(*result).error_string.is_null());
        let _ = CString::from_raw((*result).error_string);
    }
}
