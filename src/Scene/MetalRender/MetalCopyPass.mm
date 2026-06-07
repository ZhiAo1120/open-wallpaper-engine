#include "MetalCopyPass.hpp"

namespace wallpaper
{
namespace metal
{

MetalCopyPass::MetalCopyPass(const Desc& desc)
    : m_desc(desc) {}

MetalCopyPass::~MetalCopyPass() {
    // Resources should be destroyed before destruction
}

void MetalCopyPass::prepare(Scene& scene, MetalDevice& device, MetalRenderingResources& resources) {
    if (m_prepared) return;

    // TODO: Resolve source and destination textures from texture cache
    // This is a placeholder for the actual texture resolution logic

    m_prepared = true;
}

void MetalCopyPass::execute(MetalDevice& device, MetalRenderingResources& resources) {
    if (!m_prepared || resources.commandBuffer == nil) return;

    // Skip if no textures to copy
    if (m_desc.sourceTexture == nil || m_desc.destTexture == nil) return;

    // Create blit command encoder
    id<MTLBlitCommandEncoder> blitEncoder = [resources.commandBuffer blitCommandEncoder];

    // Configure copy region
    MTLRegion sourceRegion = MTLRegionMake3D(
        m_desc.srcX, m_desc.srcY, m_desc.srcZ,
        m_desc.width, m_desc.height, m_desc.depth);

    MTLRegion destRegion = MTLRegionMake3D(
        m_desc.dstX, m_desc.dstY, m_desc.dstZ,
        m_desc.width, m_desc.height, m_desc.depth);

    // Copy texture
    [blitEncoder copyFromTexture:m_desc.sourceTexture
                     sourceSlice:0
                     sourceLevel:0
                    sourceOrigin:MTLOriginMake(0, 0, 0)
                      sourceSize:MTLSizeMake(m_desc.width, m_desc.height, m_desc.depth)
                       toTexture:m_desc.destTexture
                destinationSlice:0
                destinationLevel:0
               destinationOrigin:MTLOriginMake(m_desc.dstX, m_desc.dstY, m_desc.dstZ)];

    // Generate mipmaps if needed
    // TODO: Implement mipmap generation if required

    [blitEncoder endEncoding];
}

void MetalCopyPass::destroy(MetalDevice& device, MetalRenderingResources& resources) {
    m_desc.sourceTexture = nil;
    m_desc.destTexture = nil;
    m_prepared = false;
}

} // namespace metal
} // namespace wallpaper
