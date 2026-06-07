#pragma once

#include "MetalPass.hpp"
#include "Scene/Scene.h"

namespace wallpaper
{
namespace metal
{

/// Metal render pass for frame initialization (clearing the default render target).
class MetalPrePass : public MetalPass {
public:
    struct Desc {
        // Clear color (RGBA)
        float clearColor[4] = {0.0f, 0.0f, 0.0f, 1.0f};

        // Default render target texture
        id<MTLTexture> defaultRenderTarget = nil;

        // Clear depth
        float clearDepth = 1.0f;
        bool clearDepthBuffer = false;
    };

    MetalPrePass(const Desc& desc);
    ~MetalPrePass() override;

    void prepare(Scene& scene, MetalDevice& device, MetalRenderingResources& resources) override;
    void execute(MetalDevice& device, MetalRenderingResources& resources) override;
    void destroy(MetalDevice& device, MetalRenderingResources& resources) override;

    Desc& desc() { return m_desc; }
    const Desc& desc() const { return m_desc; }

private:
    Desc m_desc;
};

} // namespace metal
} // namespace wallpaper
