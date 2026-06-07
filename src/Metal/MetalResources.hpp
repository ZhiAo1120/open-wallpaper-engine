#pragma once

#include <Metal/Metal.h>
#include <cstdint>
#include <vector>

namespace wallpaper
{
namespace metal
{

/// Per-frame rendering resources.
struct MetalRenderingResources {
    id<MTLCommandBuffer> commandBuffer;
    id<MTLRenderCommandEncoder> renderEncoder;
    id<MTLBlitCommandEncoder> blitEncoder;

    // Viewport and scissor
    MTLViewport viewport;
    MTLScissorRect scissor;

    // Horizontal flip flag
    bool horizontalFlip;

    // Frame index
    uint64_t frameIndex;
};

/// Metal texture with metadata.
struct MetalImageParameters {
    id<MTLTexture> texture;
    id<MTLSamplerState> sampler;
    uint32_t width;
    uint32_t height;
    uint32_t depth;
    uint32_t mipLevels;
    MTLPixelFormat pixelFormat;
    MTLTextureUsage usage;
    MTLStorageMode storageMode;
};

/// Metal buffer with metadata.
struct MetalBufferParameters {
    id<MTLBuffer> buffer;
    uint64_t size;
    MTLResourceOptions options;
};

/// Metal render pass attachment.
struct MetalRenderPassAttachment {
    id<MTLTexture> texture;
    MTLLoadAction loadAction;
    MTLStoreAction storeAction;
    double clearColor[4]; // Use double array instead of MTLClearValue
};

/// Metal render pipeline state configuration.
struct MetalPipelineConfig {
    id<MTLFunction> vertexFunction;
    id<MTLFunction> fragmentFunction;
    MTLPixelFormat colorAttachmentFormat;
    MTLPixelFormat depthAttachmentFormat;
    bool blendingEnabled;
    MTLBlendFactor sourceRGBBlendFactor;
    MTLBlendFactor destinationRGBBlendFactor;
    MTLBlendOperation rgbBlendOperation;
    MTLBlendFactor sourceAlphaBlendFactor;
    MTLBlendFactor destinationAlphaBlendFactor;
    MTLBlendOperation alphaBlendOperation;
    MTLDepthClipMode depthClipMode;
    MTLCullMode cullMode;
    MTLWinding windingOrder;
    MTLPrimitiveType primitiveType;
};

/// Default pipeline configuration.
inline MetalPipelineConfig defaultPipelineConfig() {
    MetalPipelineConfig config;
    config.vertexFunction = nil;
    config.fragmentFunction = nil;
    config.colorAttachmentFormat = MTLPixelFormatBGRA8Unorm;
    config.depthAttachmentFormat = MTLPixelFormatInvalid;
    config.blendingEnabled = false;
    config.sourceRGBBlendFactor = MTLBlendFactorOne;
    config.destinationRGBBlendFactor = MTLBlendFactorZero;
    config.rgbBlendOperation = MTLBlendOperationAdd;
    config.sourceAlphaBlendFactor = MTLBlendFactorOne;
    config.destinationAlphaBlendFactor = MTLBlendFactorZero;
    config.alphaBlendOperation = MTLBlendOperationAdd;
    config.depthClipMode = MTLDepthClipModeClip;
    config.cullMode = MTLCullModeNone;
    config.windingOrder = MTLWindingCounterClockwise;
    config.primitiveType = MTLPrimitiveTypeTriangle;
    return config;
}

} // namespace metal
} // namespace wallpaper
