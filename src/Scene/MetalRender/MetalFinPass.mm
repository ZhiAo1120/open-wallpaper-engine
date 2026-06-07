#include "MetalFinPass.hpp"

namespace wallpaper
{
namespace metal
{

MetalFinPass::MetalFinPass(const Desc& desc)
    : m_desc(desc) {}

MetalFinPass::~MetalFinPass() {
    // Resources should be destroyed before destruction
}

void MetalFinPass::prepare(Scene& scene, MetalDevice& device, MetalRenderingResources& resources) {
    if (m_prepared) return;

    // Create pipeline for fullscreen quad rendering
    createPipeline(device);

    // Create vertex buffer for fullscreen quad
    createVertexBuffer(device);

    m_prepared = true;
}

void MetalFinPass::execute(MetalDevice& device, MetalRenderingResources& resources) {
    if (!m_prepared || resources.commandBuffer == nil) return;

    // Create render pass descriptor for final blit
    MTLRenderPassDescriptor* renderPassDesc = [[MTLRenderPassDescriptor alloc] init];
    renderPassDesc.colorAttachments[0].texture = m_desc.destinationTexture;
    renderPassDesc.colorAttachments[0].loadAction = MTLLoadActionDontCare;
    renderPassDesc.colorAttachments[0].storeAction = MTLStoreActionStore;

    // Create render command encoder
    id<MTLRenderCommandEncoder> renderEncoder =
        [resources.commandBuffer renderCommandEncoderWithDescriptor:renderPassDesc];

    // Set pipeline state
    if (m_pipelineState != nil) {
        [renderEncoder setRenderPipelineState:m_pipelineState];
    }

    // Set viewport
    [renderEncoder setViewport:m_desc.viewport];

    // Set scissor rect
    [renderEncoder setScissorRect:m_desc.scissor];

    // Bind vertex buffer
    if (m_vertexBuffer != nil) {
        [renderEncoder setVertexBuffer:m_vertexBuffer offset:0 atIndex:0];
    }

    // Bind source texture (default render target)
    if (m_desc.sourceTexture != nil) {
        [renderEncoder setFragmentTexture:m_desc.sourceTexture atIndex:0];
    }

    // Draw fullscreen quad (4 vertices)
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];

    // End encoding
    [renderEncoder endEncoding];
}

void MetalFinPass::destroy(MetalDevice& device, MetalRenderingResources& resources) {
    m_pipelineState = nil;
    m_vertexBuffer = nil;
    m_desc.sourceTexture = nil;
    m_desc.destinationTexture = nil;
    m_prepared = false;
}

void MetalFinPass::createPipeline(MetalDevice& device) {
    if (device.device() == nil) return;

    // TODO: Create pipeline with vertex and fragment shaders
    // For now, this is a placeholder
    // In production, you would compile the fullscreen quad shaders
}

void MetalFinPass::createVertexBuffer(MetalDevice& device) {
    if (device.device() == nil) return;

    // Define fullscreen quad vertices (position + texture coordinates)
    struct Vertex {
        float position[2];
        float texCoord[2];
    };

    // Standard fullscreen quad
    Vertex vertices[] = {
        {{-1.0f, -1.0f}, {0.0f, 1.0f}},  // Bottom-left
        {{ 1.0f, -1.0f}, {1.0f, 1.0f}},  // Bottom-right
        {{-1.0f,  1.0f}, {0.0f, 0.0f}},  // Top-left
        {{ 1.0f,  1.0f}, {1.0f, 0.0f}},  // Top-right
    };

    // Flip horizontally if needed
    if (m_desc.horizontalFlip) {
        for (auto& vertex : vertices) {
            vertex.texCoord[0] = 1.0f - vertex.texCoord[0];
        }
    }

    // Create vertex buffer
    m_vertexBuffer = [device.device() newBufferWithBytes:vertices
                                                length:sizeof(vertices)
                                               options:MTLResourceStorageModeShared];
}

} // namespace metal
} // namespace wallpaper
