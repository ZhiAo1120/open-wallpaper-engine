#pragma once

#include "MetalPass.hpp"
#include "../../Metal/MetalPipeline.hpp"
#include "../../Metal/MetalTextureCache.hpp"
#include "../../Metal/MetalStagingBuffer.hpp"
#include "../Scene.h"
#include <string>
#include <vector>
#include <memory>

namespace wallpaper
{
namespace metal
{

/// Metal render pass for custom shader materials.
class MetalCustomShaderPass : public MetalPass {
public:
    struct Desc {
        struct TextureBinding {
            int32_t textureIndex = -1;
            int32_t samplerIndex = -1;
        };

        // Input
        SceneNode* node = nullptr;
        std::vector<std::string> textures;
        std::string output;
        uint32_t materialSlot = 0;
        bool clearOnFirstUse = false;
        bool preserveTargetContents = false;
        bool writeAlpha = true;

        // Prepared
        std::vector<id<MTLTexture>> metalTextures;
        std::vector<TextureBinding> textureBindings;
        id<MTLTexture> outputTexture = nil;

        // Pipeline
        MTLClearValue clearColor;
        bool blending = false;
        id<MTLRenderPipelineState> pipelineState = nil;
        id<MTLDepthStencilState> depthStencilState = nil;
        uint32_t drawCount = 0;

        // Uniforms
        id<MTLBuffer> uniformBuffer = nil;
        uint32_t uniformSize = 0;
    };

    MetalCustomShaderPass(const Desc& desc);
    ~MetalCustomShaderPass() override;

    void prepare(Scene& scene, MetalDevice& device, MetalRenderingResources& resources) override;
    void execute(MetalDevice& device, MetalRenderingResources& resources) override;
    void destroy(MetalDevice& device, MetalRenderingResources& resources) override;

    Desc& desc() { return m_desc; }
    const Desc& desc() const { return m_desc; }

private:
    void createPipeline(MetalDevice& device);
    void createUniformBuffer(MetalDevice& device);
    void bindTextures(MetalDevice& device);

    Desc m_desc;
    MetalPipeline m_pipeline;
};

} // namespace metal
} // namespace wallpaper
