#pragma once

#include "MetalPass.hpp"
#include "../../Metal/MetalTextureCache.hpp"
#include "../Scene.h"
#include <string>

namespace wallpaper
{
namespace metal
{

/// Metal render pass for texture-to-texture copy operations.
class MetalCopyPass : public MetalPass {
public:
    struct Desc {
        // Source texture key
        std::string sourceKey;
        // Destination texture key
        std::string destKey;

        // Prepared textures
        id<MTLTexture> sourceTexture = nil;
        id<MTLTexture> destTexture = nil;

        // Copy region
        uint32_t srcX = 0;
        uint32_t srcY = 0;
        uint32_t srcZ = 0;
        uint32_t dstX = 0;
        uint32_t dstY = 0;
        uint32_t dstZ = 0;
        uint32_t width = 0;
        uint32_t height = 0;
        uint32_t depth = 1;
    };

    MetalCopyPass(const Desc& desc);
    ~MetalCopyPass() override;

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
