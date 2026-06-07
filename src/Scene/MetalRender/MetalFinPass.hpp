#pragma once

#include "MetalPass.hpp"
#include "../../Metal/MetalPipeline.hpp"
#include "../../Metal/MetalTextureCache.hpp"
#include "../../Metal/MetalStagingBuffer.hpp"
#include "../Scene.h"

namespace wallpaper
{
namespace metal
{

/// Metal render pass for final blit-to-surface rendering.
class MetalFinPass : public MetalPass {
public:
    struct Desc {
        // Source texture (default render target)
        id<MTLTexture> sourceTexture = nil;

        // Destination drawable
        id<MTLTexture> destinationTexture = nil;

        // Viewport
        MTLViewport viewport;
        MTLScissorRect scissor;

        // Horizontal flip flag
        bool horizontalFlip = false;
    };

    MetalFinPass(const Desc& desc);
    ~MetalFinPass() override;

    void prepare(Scene& scene, MetalDevice& device, MetalRenderingResources& resources) override;
    void execute(MetalDevice& device, MetalRenderingResources& resources) override;
    void destroy(MetalDevice& device, MetalRenderingResources& resources) override;

    Desc& desc() { return m_desc; }
    const Desc& desc() const { return m_desc; }

private:
    void createPipeline(MetalDevice& device);
    void createVertexBuffer(MetalDevice& device);

    Desc m_desc;
    MetalPipeline m_pipeline;
    id<MTLBuffer> m_vertexBuffer = nil;
    id<MTLRenderPipelineState> m_pipelineState = nil;
};

} // namespace metal
} // namespace wallpaper
