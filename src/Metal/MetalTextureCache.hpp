#pragma once

#include <Metal/Metal.h>
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <memory>

namespace wallpaper
{
namespace metal
{

/// Texture descriptor for creating Metal textures.
struct MetalTextureDesc {
    uint32_t width = 0;
    uint32_t height = 0;
    uint32_t depth = 1;
    uint32_t mipLevels = 1;
    uint32_t arrayLength = 1;
    MTLPixelFormat pixelFormat = MTLPixelFormatRGBA8Unorm;
    MTLTextureUsage usage = MTLTextureUsageShaderRead;
    MTLStorageMode storageMode = MTLStorageModeManaged;
    bool generateMipmaps = false;
};

/// Cached Metal texture with associated metadata.
struct MetalTextureEntry {
    id<MTLTexture> texture;
    MetalTextureDesc desc;
    uint64_t lastAccessFrame;
};

/// Sampler descriptor for creating Metal samplers.
struct MetalSamplerDesc {
    MTLSamplerMinMagFilter minFilter = MTLSamplerMinMagFilterLinear;
    MTLSamplerMinMagFilter magFilter = MTLSamplerMinMagFilterLinear;
    MTLSamplerMipFilter mipFilter = MTLSamplerMipFilterNotMipmapped;
    MTLSamplerAddressMode addressS = MTLSamplerAddressModeRepeat;
    MTLSamplerAddressMode addressT = MTLSamplerAddressModeRepeat;
    MTLSamplerAddressMode addressR = MTLSamplerAddressModeRepeat;
    float lodMinClamp = 0.0f;
    float lodMaxClamp = 1000.0f;
    uint32_t maxAnisotropy = 1;
    bool normalizedCoordinates = true;
};

/// Central texture management for Metal rendering.
class MetalTextureCache {
public:
    MetalTextureCache();
    ~MetalTextureCache();

    /// Initializes the texture cache with the given Metal device.
    bool init(id<MTLDevice> device);

    /// Creates a texture from raw pixel data.
    /// @param key Unique texture key for caching.
    /// @param desc Texture descriptor.
    /// @param data Raw pixel data (optional, for initial upload).
    /// @param dataSize Size of the data in bytes.
    /// @return Texture ID, or nil on failure.
    id<MTLTexture> createTexture(
        const std::string& key,
        const MetalTextureDesc& desc,
        const void* data = nullptr,
        uint32_t dataSize = 0);

    /// Creates a texture from an existing Metal texture (for import).
    id<MTLTexture> createTextureFromExisting(
        const std::string& key,
        id<MTLTexture> texture);

    /// Queries the cache for an existing texture.
    id<MTLTexture> query(const std::string& key) const;

    /// Removes a texture from the cache.
    void remove(const std::string& key);

    /// Clears all cached textures.
    void clear();

    /// Updates the last access frame for a texture.
    void touch(const std::string& key, uint64_t frame);

    /// Evicts textures not accessed for the given number of frames.
    void evict(uint64_t currentFrame, uint64_t maxAgeFrames = 300);

    /// Creates a sampler state with the given descriptor.
    id<MTLSamplerState> createSampler(const MetalSamplerDesc& desc);

    /// Returns the number of cached textures.
    size_t textureCount() const { return m_textures.size(); }

    /// Returns the total GPU memory used by cached textures (approximate).
    uint64_t totalMemoryUsage() const;

private:
    /// Estimates the memory usage of a texture.
    static uint64_t estimateTextureMemory(const MetalTextureDesc& desc);

    id<MTLDevice> m_device;
    std::unordered_map<std::string, MetalTextureEntry> m_textures;
    std::vector<id<MTLSamplerState>> m_samplers;
};

} // namespace metal
} // namespace wallpaper
