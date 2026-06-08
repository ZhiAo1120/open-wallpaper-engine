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

/// Cached Metal texture with associated metadata.
struct MetalTextureEntry {
    id<MTLTexture> texture;
    MetalTextureDesc desc;
    uint64_t memBytes;         ///< Estimated memory footprint.
    uint64_t lastAccessFrame;  ///< Last frame this texture was touched.
};

/// Central texture management for Metal rendering.
///
/// Uses an LRU (least-recently-used) eviction strategy backed by a doubly-
/// linked list + hash map for O(1) touch / eviction.  A configurable memory
/// ceiling (default 512 MB) is enforced lazily on each `createTexture` call.
class MetalTextureCache {
public:
    MetalTextureCache();
    ~MetalTextureCache();

    /// Initializes the texture cache with the given Metal device.
    bool init(id<MTLDevice> device);

    // ── Memory limit ────────────────────────────────────────────────────

    /// Sets the maximum memory (in bytes) the cache may occupy.
    void setMaxMemoryLimit(uint64_t maxBytes) { m_maxMemoryBytes = maxBytes; }

    /// Returns the current memory ceiling.
    [[nodiscard]] uint64_t maxMemoryLimit() const noexcept { return m_maxMemoryBytes; }

    /// Returns the tracked memory usage of all cached textures (bytes).
    [[nodiscard]] uint64_t currentMemoryUsage() const noexcept { return m_currentMemoryBytes; }

    // ── Texture lifecycle ───────────────────────────────────────────────

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

    /// Queries the cache for an existing texture and marks it most-recently-used.
    id<MTLTexture> query(const std::string& key);

    /// Removes a texture from the cache.
    void remove(const std::string& key);

    /// Clears all cached textures.
    void clear();

    /// Updates the last access frame for a texture (alias for `query` touch).
    void touch(const std::string& key, uint64_t frame);

    /// Evicts textures not accessed for the given number of frames.
    void evict(uint64_t currentFrame, uint64_t maxAgeFrames = 300);

    /// Creates a sampler state with the given descriptor.
    id<MTLSamplerState> createSampler(const MetalSamplerDesc& desc);

    /// Returns the number of cached textures.
    [[nodiscard]] size_t textureCount() const noexcept { return m_textures.size(); }

    /// Returns the total GPU memory used by cached textures.
    [[nodiscard]] uint64_t totalMemoryUsage() const noexcept { return m_currentMemoryBytes; }

private:
    /// Estimates the memory usage of a texture.
    static uint64_t estimateTextureMemory(const MetalTextureDesc& desc);

    /// Evicts least-recently-used textures until `bytesNeeded` can be
    /// accommodated. Textures with lower `lastAccessFrame` are evicted first.
    void evictUntilFit(uint64_t bytesNeeded);

    id<MTLDevice> m_device;
    std::unordered_map<std::string, MetalTextureEntry> m_textures;
    std::vector<id<MTLSamplerState>> m_samplers;

    /// Memory accounting.
    uint64_t m_currentMemoryBytes = 0;
    uint64_t m_maxMemoryBytes    = 384 * 1024 * 1024;  // 384 MB default
};

} // namespace metal
} // namespace wallpaper
