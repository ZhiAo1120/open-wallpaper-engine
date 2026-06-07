#include "MetalTextureCache.hpp"
#include <algorithm>

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

id<MTLTexture> MetalTextureCache::createTexture(
    const std::string& key,
    const MetalTextureDesc& desc,
    const void* data,
    uint32_t dataSize) {

    if (m_device == nil || key.empty() || desc.width == 0 || desc.height == 0) {
        return nil;
    }

    // Check cache first
    auto it = m_textures.find(key);
    if (it != m_textures.end()) {
        return it->second.texture;
    }

    // Create texture descriptor
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

    // Create texture
    id<MTLTexture> texture = [m_device newTextureWithDescriptor:texDesc];
    if (texture == nil) {
        return nil;
    }

    // Upload initial data if provided
    if (data != nullptr && dataSize > 0) {
        MTLRegion region = MTLRegionMake3D(0, 0, 0, desc.width, desc.height, desc.depth);
        uint32_t bytesPerRow = desc.width * 4; // Assume 4 bytes per pixel for RGBA
        [texture replaceRegion:region
                   mipmapLevel:0
                     withBytes:data
                   bytesPerRow:bytesPerRow
                 bytesPerImage:desc.width * desc.height * 4];
    }

    // Cache the texture
    MetalTextureEntry entry;
    entry.texture = texture;
    entry.desc = desc;
    entry.lastAccessFrame = 0;
    m_textures[key] = entry;

    return texture;
}

id<MTLTexture> MetalTextureCache::createTextureFromExisting(
    const std::string& key,
    id<MTLTexture> texture) {

    if (m_device == nil || key.empty() || texture == nil) {
        return nil;
    }

    // Check cache first
    auto it = m_textures.find(key);
    if (it != m_textures.end()) {
        return it->second.texture;
    }

    // Cache the existing texture
    MetalTextureEntry entry;
    entry.texture = texture;
    entry.desc.width = static_cast<uint32_t>(texture.width);
    entry.desc.height = static_cast<uint32_t>(texture.height);
    entry.desc.depth = static_cast<uint32_t>(texture.depth);
    entry.desc.mipLevels = static_cast<uint32_t>(texture.mipmapLevelCount);
    entry.desc.pixelFormat = texture.pixelFormat;
    entry.desc.usage = texture.usage;
    entry.desc.storageMode = texture.storageMode;
    entry.lastAccessFrame = 0;
    m_textures[key] = entry;

    return texture;
}

id<MTLTexture> MetalTextureCache::query(const std::string& key) const {
    auto it = m_textures.find(key);
    if (it != m_textures.end()) {
        return it->second.texture;
    }
    return nil;
}

void MetalTextureCache::remove(const std::string& key) {
    m_textures.erase(key);
}

void MetalTextureCache::clear() {
    m_textures.clear();
    m_samplers.clear();
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

uint64_t MetalTextureCache::totalMemoryUsage() const {
    uint64_t total = 0;
    for (const auto& [key, entry] : m_textures) {
        total += estimateTextureMemory(entry.desc);
    }
    return total;
}

uint64_t MetalTextureCache::estimateTextureMemory(const MetalTextureDesc& desc) {
    // Rough estimate: width * height * depth * bytes_per_pixel * mip_levels
    uint32_t bytesPerPixel = 4; // Default to RGBA8
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

    uint64_t baseSize = static_cast<uint64_t>(desc.width) * desc.height * desc.depth * bytesPerPixel;
    // Account for mip levels (geometric series sum)
    uint64_t totalSize = 0;
    uint32_t mipWidth = desc.width;
    uint32_t mipHeight = desc.height;
    for (uint32_t i = 0; i < desc.mipLevels; ++i) {
        totalSize += static_cast<uint64_t>(mipWidth) * mipHeight * desc.depth * bytesPerPixel;
        mipWidth = std::max(1u, mipWidth / 2);
        mipHeight = std::max(1u, mipHeight / 2);
    }

    return totalSize;
}

} // namespace metal
} // namespace wallpaper
