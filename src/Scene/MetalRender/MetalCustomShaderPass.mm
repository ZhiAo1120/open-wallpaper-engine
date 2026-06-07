#include "MetalCustomShaderPass.hpp"
#include "../../Metal/MetalPipeline.hpp"
#include <algorithm>

namespace wallpaper
{
namespace metal
{

MetalCustomShaderPass::MetalCustomShaderPass(const Desc& desc)
    : m_desc(desc) {}

MetalCustomShaderPass::~MetalCustomShaderPass() {
    // Resources should be destroyed before destruction
}

void MetalCustomShaderPass::prepare(Scene& scene, MetalDevice& device, MetalRenderingResources& resources) {
    if (m_prepared) return;

    // Create pipeline state
    createPipeline(device);

    // Create uniform buffer if needed
    createUniformBuffer(device);

    // Bind textures
    bindTextures(device);

    m_prepared = true;
}

void MetalCustomShaderPass::execute(MetalDevice& device, MetalRenderingResources& resources) {
    if (!m_prepared || resources.renderEncoder == nil) return;

    id<MTLRenderCommandEncoder> encoder = resources.renderEncoder;

    // Set pipeline state
    if (m_desc.pipelineState != nil) {
        [encoder setRenderPipelineState:m_desc.pipelineState];
    }

    // Set depth stencil state
    if (m_desc.depthStencilState != nil) {
        [encoder setDepthStencilState:m_desc.depthStencilState];
    }

    // Set viewport
    [encoder setViewport:resources.viewport];

    // Set scissor rect
    [encoder setScissorRect:resources.scissor];

    // Bind uniform buffer
    if (m_desc.uniformBuffer != nil) {
        [encoder setVertexBuffer:m_desc.uniformBuffer offset:0 atIndex:0];
        [encoder setFragmentBuffer:m_desc.uniformBuffer offset:0 atIndex:0];
    }

    // Bind textures
    for (size_t i = 0; i < m_desc.metalTextures.size(); ++i) {
        if (m_desc.metalTextures[i] != nil) {
            [encoder setFragmentTexture:m_desc.metalTextures[i] atIndex:i];
        }
    }

    // Issue draw calls
    // TODO: Implement actual draw calls based on scene mesh data
    // This is a placeholder for the actual rendering logic
}

void MetalCustomShaderPass::destroy(MetalDevice& device, MetalRenderingResources& resources) {
    m_desc.pipelineState = nil;
    m_desc.depthStencilState = nil;
    m_desc.uniformBuffer = nil;
    m_desc.metalTextures.clear();
    m_prepared = false;
}

void MetalCustomShaderPass::createPipeline(MetalDevice& device) {
    if (device.device() == nil) return;

    // Create pipeline configuration
    MetalPipelineConfig config = defaultPipelineConfig();
    config.blendingEnabled = m_desc.blending;
    config.colorAttachmentFormat = MTLPixelFormatBGRA8Unorm;

    // TODO: Set vertex and fragment functions from shader compilation
    // For now, this is a placeholder
    // config.vertexFunction = ...;
    // config.fragmentFunction = ...;

    // Generate cache key
    std::string cacheKey = "custom_shader_" + std::to_string(m_desc.materialSlot);

    // Create pipeline state
    m_desc.pipelineState = m_pipeline.createPipeline(config, cacheKey);
}

void MetalCustomShaderPass::createUniformBuffer(MetalDevice& device) {
    if (device.device() == nil || m_desc.uniformSize == 0) return;

    // Create uniform buffer
    m_desc.uniformBuffer = [device.device() newBufferWithLength:m_desc.uniformSize
                                                      options:MTLResourceStorageModeShared];
}

void MetalCustomShaderPass::bindTextures(MetalDevice& device) {
    // TODO: Bind textures from texture cache
    // This is a placeholder for the actual texture binding logic
}

} // namespace metal
} // namespace wallpaper
