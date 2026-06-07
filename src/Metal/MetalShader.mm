#include "MetalShader.hpp"
#include <sstream>

namespace wallpaper
{
namespace metal
{

MetalShader::MetalShader()
    : m_device(nil)
    , m_defaultLibrary(nil) {}

MetalShader::~MetalShader() {
    clear();
    m_defaultLibrary = nil;
    m_device = nil;
}

bool MetalShader::init(id<MTLDevice> device) {
    if (device == nil) return false;

    m_device = device;

    // Create default library for built-in functions
    m_defaultLibrary = [m_device newDefaultLibrary];
    if (m_defaultLibrary == nil) {
        // Try creating an empty library as fallback
        NSError* error = nil;
        m_defaultLibrary = [m_device newLibraryWithSource:@""
                                                   error:&error];
        if (m_defaultLibrary == nil) {
            return false;
        }
    }

    return true;
}

std::shared_ptr<MetalShaderProgram> MetalShader::compile(
    const std::string& vertexSource,
    const std::string& fragmentSource,
    const std::string& cacheKey) {

    // Check cache first
    auto it = m_shaders.find(cacheKey);
    if (it != m_shaders.end()) {
        return it->second;
    }

    // Compile vertex shader
    id<MTLLibrary> vertexLib = createLibrary(vertexSource, @"vertex shader");
    if (vertexLib == nil) {
        return nullptr;
    }

    id<MTLFunction> vertexFunc = [vertexLib newFunctionWithName:@"main"];
    if (vertexFunc == nil) {
        return nullptr;
    }

    // Compile fragment shader
    id<MTLLibrary> fragmentLib = createLibrary(fragmentSource, @"fragment shader");
    if (fragmentLib == nil) {
        return nullptr;
    }

    id<MTLFunction> fragmentFunc = [fragmentLib newFunctionWithName:@"main"];
    if (fragmentFunc == nil) {
        return nullptr;
    }

    // Create shader program
    auto program = std::make_shared<MetalShaderProgram>();
    program->vertexFunction = vertexFunc;
    program->fragmentFunction = fragmentFunc;
    program->vertexSource = vertexSource;
    program->fragmentSource = fragmentSource;
    program->cacheKey = cacheKey;

    // Cache the program
    m_shaders[cacheKey] = program;

    return program;
}

std::shared_ptr<MetalShaderProgram> MetalShader::compileFromSPIRV(
    const uint32_t* vertexSPIRV,
    uint32_t vertexWordCount,
    const uint32_t* fragmentSPIRV,
    uint32_t fragmentWordCount,
    const std::string& cacheKey) {

    // TODO: Implement SPIR-V to MSL cross-compilation using Naga
    // For now, this is a placeholder
    (void)vertexSPIRV;
    (void)vertexWordCount;
    (void)fragmentSPIRV;
    (void)fragmentWordCount;
    (void)cacheKey;

    return nullptr;
}

std::shared_ptr<MetalShaderProgram> MetalShader::compileFromHLSL(
    const std::string& vertexSource,
    const std::string& fragmentSource,
    const std::string& cacheKey) {

    // Check cache first
    auto it = m_shaders.find(cacheKey);
    if (it != m_shaders.end()) {
        return it->second;
    }

    // TODO: Use Rust shader bridge to compile HLSL to MSL
    // This would call rs_shader_compile_program with target="metal_msl"
    // For now, return nullptr as the bridge integration is not yet complete
    (void)vertexSource;
    (void)fragmentSource;
    (void)cacheKey;

    return nullptr;
}

std::shared_ptr<MetalShaderProgram> MetalShader::query(const std::string& cacheKey) const {
    auto it = m_shaders.find(cacheKey);
    if (it != m_shaders.end()) {
        return it->second;
    }
    return nullptr;
}

void MetalShader::remove(const std::string& cacheKey) {
    m_shaders.erase(cacheKey);
}

void MetalShader::clear() {
    m_shaders.clear();
}

id<MTLLibrary> MetalShader::createLibrary(const std::string& source, NSString* label) {
    if (m_device == nil || source.empty()) {
        return nil;
    }

    NSString* sourceStr = [NSString stringWithUTF8String:source.c_str()];

    NSError* error = nil;
    MTLCompileOptions* options = [[MTLCompileOptions alloc] init];
    options.languageVersion = MTLLanguageVersion2_0;

    id<MTLLibrary> library = [m_device newLibraryWithSource:sourceStr
                                                   options:options
                                                     error:&error];

    if (library == nil) {
        // Log error
        if (error != nil) {
            NSLog(@"Metal shader compilation failed: %@", [error localizedDescription]);
        }
        return nil;
    }

    library.label = label;
    return library;
}

} // namespace metal
} // namespace wallpaper
