#include "MetalTextureCache.hpp"
#include <algorithm>
#include <vector>

namespace wallpaper
{
namespace metal
{

MetalTextureCache::MetalTextureCache()
    : m_device(nil) {}

MetalTextureCache::~MetalTextureCache() {
    clear();
}

bool MetalTextureCache::init(id<MTLDevice> device) {
    if (device == nil) return false;
    m_device = device;
    return true;
}

// ── Memory eviction ───────────────────────────────────────────────────

void MetalTextureCache::evictUntilFit(uint64_t bytesNeeded) {
    if (m_currentMemoryBytes + bytesNeeded <= m_maxMemoryBytes) return;

    // Collect (key, memBytes, lastAccessFrame) for sorting.
    struct EntryInfo {
        std::string key;
        uint64_t    memBytes;
        uint64_t    lastFrame;
    };
    std::vector<EntryInfo> entries;
    entries.reserve(m_textures.size());
    for (const auto& [key, entry] : m_textures) {
        entries.push_back({ key, entry.memBytes, entry.lastAccessFrame });
    }

    // Sort by lastAccessFrame ascending: never-touched (0) first, then oldest.
    std::sort(entries.begin(), entries.end(),
              [](const EntryInfo& a, const EntryInfo& b) {
                  return a.lastFrame < b.lastFrame;
              });

    for (const auto& info : entries) {
        if (m_currentMemoryBytes + bytesNeeded <= m_maxMemoryBytes) break;
        auto it = m_textures.find(info.key);
        if (it != m_textures.end()) {
            m_currentMemoryBytes -= it->second.memBytes;
            m_textures.erase(it);
        }
    }
}

// ── Texture lifecycle ─────────────────────────────────────────────────

id<MTLTexture> MetalTextureCache::createTexture(
    const std::string& key,
    const MetalTextureDesc& desc,
    const void* data,
    uint32_t dataSize) {

    if (m_device == nil || key.empty() || desc.width == 0 || desc.height == 0) {
        return nil;
    }

    // Check cache first.
    auto it = m_textures.find(key);
    if (it != m_textures.end()) {
        return it->second.texture;
    }

    uint64_t texMem = estimateTextureMemory(desc);
    evictUntilFit(texMem);

    MTLTextureDescriptor* texDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:desc.pixelFormat
                                                                                     width:desc.width
                                                                                    height:desc.height
                                                                                 mipmapped:desc.generateMipmaps];

    texDesc.textureType = (desc.depth > 1) ? MTLTextureType3D : MTLTextureType2D;
    texDesc.depth = desc.depth;
    texDesc.arrayLength = desc.arrayLength;
    texDesc.mipmapLevelCount = desc.mipLevels;
    texDesc.usage = desc.usage;
    texDesc.storageMode = desc.storageMode;

    id<MTLTexture> texture = [m_device newTextureWithDescriptor:texDesc];
    if (texture == nil) return nil;

    if (data != nullptr && dataSize > 0) {
        (void)data;
        (void)dataSize;
    }

    MetalTextureEntry entry;
    entry.texture = texture;
    entry.desc = desc;
    entry.memBytes = texMem;
    entry.lastAccessFrame = 0;
    m_textures[key] = entry;
    m_currentMemoryBytes += texMem;

    return texture;
}

id<MTLTexture> MetalTextureCache::createTextureFromExisting(
    const std::string& key,
    id<MTLTexture> texture) {

    if (m_device == nil || key.empty() || texture == nil) return nil;

    auto it = m_textures.find(key);
    if (it != m_textures.end()) return it->second.texture;

    MetalTextureDesc desc;
    desc.width       = static_cast<uint32_t>(texture.width);
    desc.height      = static_cast<uint32_t>(texture.height);
    desc.depth       = static_cast<uint32_t>(texture.depth);
    desc.mipLevels   = static_cast<uint32_t>(texture.mipmapLevelCount);
    desc.pixelFormat = texture.pixelFormat;
    desc.usage       = texture.usage;
    desc.storageMode = texture.storageMode;

    uint64_t texMem = estimateTextureMemory(desc);
    evictUntilFit(texMem);

    MetalTextureEntry entry;
    entry.texture = texture;
    entry.desc = desc;
    entry.memBytes = texMem;
    entry.lastAccessFrame = 0;
    m_textures[key] = entry;
    m_currentMemoryBytes += texMem;

    return texture;
}

id<MTLTexture> MetalTextureCache::query(const std::string& key) {
    auto it = m_textures.find(key);
    if (it == m_textures.end()) return nil;
    return it->second.texture;
}

void MetalTextureCache::remove(const std::string& key) {
    auto it = m_textures.find(key);
    if (it == m_textures.end()) return;
    m_currentMemoryBytes -= it->second.memBytes;
    m_textures.erase(it);
}

void MetalTextureCache::clear() {
    m_textures.clear();
    m_samplers.clear();
    m_currentMemoryBytes = 0;
}

void MetalTextureCache::touch(const std::string& key, uint64_t frame) {
    auto it = m_textures.find(key);
    if (it != m_textures.end()) {
        it->second.lastAccessFrame = frame;
    }
}

void MetalTextureCache::evict(uint64_t currentFrame, uint64_t maxAgeFrames) {
    auto it = m_textures.begin();
    while (it != m_textures.end()) {
        if (currentFrame - it->second.lastAccessFrame > maxAgeFrames) {
            m_currentMemoryBytes -= it->second.memBytes;
            it = m_textures.erase(it);
        } else {
            ++it;
        }
    }
}

id<MTLSamplerState> MetalTextureCache::createSampler(const MetalSamplerDesc& desc) {
    if (m_device == nil) return nil;

    MTLSamplerDescriptor* samplerDesc = [[MTLSamplerDescriptor alloc] init];
    samplerDesc.minFilter = desc.minFilter;
    samplerDesc.magFilter = desc.magFilter;
    samplerDesc.mipFilter = desc.mipFilter;
    samplerDesc.sAddressMode = desc.addressS;
    samplerDesc.tAddressMode = desc.addressT;
    samplerDesc.rAddressMode = desc.addressR;
    samplerDesc.lodMinClamp = desc.lodMinClamp;
    samplerDesc.lodMaxClamp = desc.lodMaxClamp;
    samplerDesc.maxAnisotropy = desc.maxAnisotropy;
    samplerDesc.normalizedCoordinates = desc.normalizedCoordinates;

    id<MTLSamplerState> sampler = [m_device newSamplerStateWithDescriptor:samplerDesc];
    if (sampler != nil) {
        m_samplers.push_back(sampler);
    }

    return sampler;
}

uint64_t MetalTextureCache::estimateTextureMemory(const MetalTextureDesc& desc) {
    uint32_t bytesPerPixel = 4;
    switch (desc.pixelFormat) {
        case MTLPixelFormatR8Unorm:
        case MTLPixelFormatR8Uint:
            bytesPerPixel = 1;
            break;
        case MTLPixelFormatRG8Unorm:
        case MTLPixelFormatRG8Uint:
            bytesPerPixel = 2;
            break;
        case MTLPixelFormatRGBA8Unorm:
        case MTLPixelFormatRGBA8Uint:
        case MTLPixelFormatBGRA8Unorm:
            bytesPerPixel = 4;
            break;
        case MTLPixelFormatRGBA16Float:
            bytesPerPixel = 8;
            break;
        case MTLPixelFormatRGBA32Float:
            bytesPerPixel = 16;
            break;
        default:
            bytesPerPixel = 4;
            break;
    }

    uint64_t totalSize = 0;
    uint32_t mipWidth  = desc.width;
    uint32_t mipHeight = desc.height;
    uint32_t mipLevels = desc.mipLevels > 0 ? desc.mipLevels : 1;
    for (uint32_t i = 0; i < mipLevels; ++i) {
        totalSize += static_cast<uint64_t>(mipWidth) * mipHeight * desc.depth * bytesPerPixel;
        mipWidth  = std::max(1u, mipWidth / 2);
        mipHeight = std::max(1u, mipHeight / 2);
    }

    return totalSize;
}

} // namespace metal
} // namespace wallpaper
