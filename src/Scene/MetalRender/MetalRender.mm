#include "MetalRender.hpp"
#include "MetalSceneToRenderGraph.hpp"
#include "MetalCustomShaderPass.hpp"
#include "MetalCopyPass.hpp"
#include "MetalPrePass.hpp"
#include "MetalFinPass.hpp"
#include <algorithm>

namespace wallpaper
{
namespace metal
{

MetalRender::MetalRender() = default;

MetalRender::~MetalRender() {
    destroy();
}

bool MetalRender::init(CAMetalLayer* layer, const MetalRenderConfig& config) {
    if (m_initialized) {
        destroy();
    }

    m_config = config;

    // Initialize Metal device
    if (!m_device.init(config.preferHighPerformance)) {
        return false;
    }

    // Initialize swapchain
    if (!m_swapchain.init(m_device.device(), layer, config.width, config.height)) {
        return false;
    }

    // Initialize texture cache
    if (!m_textureCache.init(m_device.device())) {
        return false;
    }

    // Initialize pipeline manager
    if (!m_pipeline.init(m_device.device())) {
        return false;
    }

    // Initialize shader compiler
    if (!m_shader.init(m_device.device())) {
        return false;
    }

    // Initialize staging buffer
    if (!m_stagingBuffer.init(m_device.device(), 1024 * 1024)) { // 1MB initial size
        return false;
    }

    // Create per-frame resources
    createFrameResources();

    m_initialized = true;
    return true;
}

void MetalRender::destroy() {
    if (!m_initialized) return;

    // Wait for GPU to finish
    m_device.waitIdle();

    // Destroy render passes
    m_preparedPasses.clear();

    // Destroy per-frame resources
    destroyFrameResources();

    // Clear caches
    m_textureCache.clear();
    m_pipeline.clear();
    m_shader.clear();

    m_initialized = false;
}

void MetalRender::compileRenderGraph(Scene& scene) {
    if (!m_initialized) return;

    // Clear previous render graph
    m_preparedPasses.clear();
    m_renderGraph = rg::RenderGraph();

    // Convert scene to render graph
    MetalSceneToRenderGraph::convert(scene, m_renderGraph);

    // Get topological order
    auto passOrder = m_renderGraph.topologicalOrder();

    // Prepare passes in order
    for (auto passId : passOrder) {
        // Get pass from render graph and prepare it
        // This is a simplified implementation - in production,
        // you would get the actual pass from the render graph
    }
}

void MetalRender::drawFrame(Scene& scene) {
    if (!m_initialized) return;

    // Acquire next drawable
    id<CAMetalDrawable> drawable = m_swapchain.acquireNextDrawable();
    if (drawable == nil) return;

    // Begin command buffer
    id<MTLCommandBuffer> commandBuffer = [m_device.commandQueue() commandBuffer];
    if (commandBuffer == nil) return;

    // Update frame resources
    m_frameResources.commandBuffer = commandBuffer;
    m_frameResources.frameIndex = m_frameIndex;

    // Create render command encoder for main rendering
    MTLRenderPassDescriptor* renderPassDesc = [[MTLRenderPassDescriptor alloc] init];
    renderPassDesc.colorAttachments[0].texture = drawable.texture;
    renderPassDesc.colorAttachments[0].loadAction = MTLLoadActionClear;
    renderPassDesc.colorAttachments[0].storeAction = MTLStoreActionStore;
    renderPassDesc.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);

    id<MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:renderPassDesc];

    m_frameResources.renderEncoder = renderEncoder;

    // Execute prepared passes
    for (auto& pass : m_preparedPasses) {
        pass->execute(m_device, m_frameResources);
    }

    // End encoding
    [renderEncoder endEncoding];

    // Present drawable
    [commandBuffer presentDrawable:drawable];

    // Commit command buffer
    [commandBuffer commit];

    // Increment frame counter
    m_frameIndex++;
}

void MetalRender::releaseSurface() {
    if (!m_initialized) return;

    // Wait for GPU to finish
    m_device.waitIdle();

    // Clear render passes
    m_preparedPasses.clear();

    // Destroy per-frame resources
    destroyFrameResources();
}

void MetalRender::resetSurface(CAMetalLayer* layer, uint32_t width, uint32_t height) {
    if (!m_initialized) return;

    // Update config
    m_config.width = width;
    m_config.height = height;

    // Reinitialize swapchain
    m_swapchain.resize(width, height);

    // Recreate per-frame resources
    createFrameResources();
}

void MetalRender::updateCameraFillMode(bool fill) {
    // TODO: Implement camera fill mode update
    (void)fill;
}

void MetalRender::setWallpaperScalingMode(uint32_t mode) {
    // TODO: Implement wallpaper scaling mode
    (void)mode;
}

void MetalRender::setWallpaperScalingFactor(float factor) {
    // TODO: Implement wallpaper scaling factor
    (void)factor;
}

void MetalRender::setHorizontalFlip(bool flip) {
    m_config.horizontalFlip = flip;
    m_frameResources.horizontalFlip = flip;
}

void MetalRender::createFrameResources() {
    // Initialize frame resources
    m_frameResources.commandBuffer = nil;
    m_frameResources.renderEncoder = nil;
    m_frameResources.blitEncoder = nil;
    m_frameResources.viewport = MTLViewportMake(0, 0, m_config.width, m_config.height, 0.0, 1.0);
    m_frameResources.scissor = MTLScissorRectMake(0, 0, m_config.width, m_config.height);
    m_frameResources.horizontalFlip = m_config.horizontalFlip;
    m_frameResources.frameIndex = 0;
}

void MetalRender::destroyFrameResources() {
    m_frameResources.commandBuffer = nil;
    m_frameResources.renderEncoder = nil;
    m_frameResources.blitEncoder = nil;
}

} // namespace metal
} // namespace wallpaper
