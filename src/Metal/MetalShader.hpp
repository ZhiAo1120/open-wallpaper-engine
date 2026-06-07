#pragma once

#include <Metal/Metal.h>
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace wallpaper
{
namespace metal
{

/// Compiled Metal shader program.
struct MetalShaderProgram {
    id<MTLFunction> vertexFunction;
    id<MTLFunction> fragmentFunction;
    std::string vertexSource;
    std::string fragmentSource;
    std::string cacheKey;
};

/// Metal shader compilation and caching.
class MetalShader {
public:
    MetalShader();
    ~MetalShader();

    /// Initializes the shader compiler with the given Metal device.
    bool init(id<MTLDevice> device);

    /// Compiles a shader from MSL source.
    /// @param vertexSource MSL source for vertex function.
    /// @param fragmentSource MSL source for fragment function.
    /// @param cacheKey Unique key for caching.
    /// @return Compiled shader program, or nullptr on failure.
    std::shared_ptr<MetalShaderProgram> compile(
        const std::string& vertexSource,
        const std::string& fragmentSource,
        const std::string& cacheKey);

    /// Compiles a shader from SPIR-V (using Naga cross-compilation).
    std::shared_ptr<MetalShaderProgram> compileFromSPIRV(
        const uint32_t* vertexSPIRV,
        uint32_t vertexWordCount,
        const uint32_t* fragmentSPIRV,
        uint32_t fragmentWordCount,
        const std::string& cacheKey);

    /// Queries the cache for an existing compiled shader.
    std::shared_ptr<MetalShaderProgram> query(const std::string& cacheKey) const;

    /// Removes a shader from the cache.
    void remove(const std::string& cacheKey);

    /// Clears all cached shaders.
    void clear();

    /// Returns the number of cached shaders.
    size_t shaderCount() const { return m_shaders.size(); }

    /// Returns the default library (for built-in functions).
    id<MTLLibrary> defaultLibrary() const { return m_defaultLibrary; }

private:
    /// Creates a Metal library from MSL source.
    id<MTLLibrary> createLibrary(const std::string& source, NSString* label);

    id<MTLDevice> m_device;
    id<MTLLibrary> m_defaultLibrary;
    std::unordered_map<std::string, std::shared_ptr<MetalShaderProgram>> m_shaders;
};

} // namespace metal
} // namespace wallpaper
