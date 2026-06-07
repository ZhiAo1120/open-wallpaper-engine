#include "MetalPrePass.hpp"

namespace wallpaper
{
namespace metal
{

MetalPrePass::MetalPrePass(const Desc& desc)
    : m_desc(desc) {}

MetalPrePass::~MetalPrePass() {
    // Resources should be destroyed before destruction
}

void MetalPrePass::prepare(Scene& scene, MetalDevice& device, MetalRenderingResources& resources) {
    if (m_prepared) return;

    // No preparation needed for pre-pass
    m_prepared = true;
}

void MetalPrePass::execute(MetalDevice& device, MetalRenderingResources& resources) {
    if (!m_prepared || resources.commandBuffer == nil) return;

    // Create render pass descriptor for clearing
    MTLRenderPassDescriptor* renderPassDesc = [[MTLRenderPassDescriptor alloc] init];

    // Configure color attachment
    if (m_desc.defaultRenderTarget != nil) {
        renderPassDesc.colorAttachments[0].texture = m_desc.defaultRenderTarget;
        renderPassDesc.colorAttachments[0].loadAction = MTLLoadActionClear;
        renderPassDesc.colorAttachments[0].storeAction = MTLStoreActionStore;
        renderPassDesc.colorAttachments[0].clearColor = MTLClearColorMake(
            m_desc.clearColor[0], m_desc.clearColor[1],
            m_desc.clearColor[2], m_desc.clearColor[3]);
    }

    // Configure depth attachment if needed
    if (m_desc.clearDepthBuffer) {
        // TODO: Create depth texture if needed
        // renderPassDesc.depthAttachment.texture = depthTexture;
        renderPassDesc.depthAttachment.loadAction = MTLLoadActionClear;
        renderPassDesc.depthAttachment.storeAction = MTLStoreActionDontCare;
        renderPassDesc.depthAttachment.clearDepth = m_desc.clearDepth;
    }

    // Create render command encoder and clear the render target
    id<MTLRenderCommandEncoder> renderEncoder =
        [resources.commandBuffer renderCommandEncoderWithDescriptor:renderPassDesc];

    // No draw calls needed - just clear the render target
    [renderEncoder endEncoding];
}

void MetalPrePass::destroy(MetalDevice& device, MetalRenderingResources& resources) {
    m_desc.defaultRenderTarget = nil;
    m_prepared = false;
}

} // namespace metal
} // namespace wallpaper
