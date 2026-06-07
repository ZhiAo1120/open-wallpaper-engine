#pragma once

#include "../../Metal/MetalDevice.hpp"
#include "../../Metal/MetalSwapchain.hpp"
#include "../../Metal/MetalTextureCache.hpp"
#include "../../Metal/MetalPipeline.hpp"
#include "../../Metal/MetalStagingBuffer.hpp"
#include "../../Metal/MetalShader.hpp"
#include "../../Metal/MetalResources.hpp"
#include "MetalPass.hpp"
#include "Scene/Scene.h"
#include "RenderGraph/RenderGraph.hpp"
#include <memory>
#include <vector>

namespace wallpaper
{
namespace metal
{

/// Metal render configuration.
struct MetalRenderConfig {
    /// Width in pixels.
    uint32_t width = 0;
    /// Height in pixels.
    uint32_t height = 0;
    /// Display scale factor.
    float scaleFactor = 1.0f;
    /// Target FPS.
    uint32_t targetFps = 60;
    /// Whether to prefer high-performance GPU.
    bool preferHighPerformance = true;
    /// Horizontal flip flag.
    bool horizontalFlip = false;
};

/// Metal renderer orchestrator.
class MetalRender {
public:
    MetalRender();
    ~MetalRender();

    /// Initializes the Metal renderer.
    /// @param layer The CAMetalLayer to render to.
    /// @param config Render configuration.
    /// @return true on success, false on failure.
    bool init(CAMetalLayer* layer, const MetalRenderConfig& config);

    /// Destroys the renderer and releases all resources.
    void destroy();

    /// Compiles the render graph from a scene.
    void compileRenderGraph(Scene& scene);

    /// Draws a frame.
    void drawFrame(Scene& scene);

    /// Releases the surface for reconfiguration.
    void releaseSurface();

    /// Resets the surface after reconfiguration.
    void resetSurface(CAMetalLayer* layer, uint32_t width, uint32_t height);

    /// Updates camera fill mode.
    void updateCameraFillMode(bool fill);

    /// Sets wallpaper scaling mode.
    void setWallpaperScalingMode(uint32_t mode);

    /// Sets wallpaper scaling factor.
    void setWallpaperScalingFactor(float factor);

    /// Sets horizontal flip.
    void setHorizontalFlip(bool flip);

    /// Returns the device.
    MetalDevice& device() { return m_device; }

    /// Returns the texture cache.
    MetalTextureCache& textureCache() { return m_textureCache; }

    /// Returns the pipeline manager.
    MetalPipeline& pipeline() { return m_pipeline; }

    /// Returns the shader compiler.
    MetalShader& shader() { return m_shader; }

    /// Returns true if the renderer is initialized.
    bool isInitialized() const { return m_initialized; }

private:
    /// Creates per-frame rendering resources.
    void createFrameResources();

    /// Destroys per-frame rendering resources.
    void destroyFrameResources();

    bool m_initialized = false;
    MetalRenderConfig m_config;

    // Metal infrastructure
    MetalDevice m_device;
    MetalSwapchain m_swapchain;
    MetalTextureCache m_textureCache;
    MetalPipeline m_pipeline;
    MetalShader m_shader;

    // Double-buffered staging
    MetalDoubleStagingBuffer m_stagingBuffer;

    // Render graph
    rg::RenderGraph m_renderGraph;
    std::vector<std::unique_ptr<MetalPass>> m_preparedPasses;

    // Per-frame resources
    MetalRenderingResources m_frameResources;

    // Frame counter
    uint64_t m_frameIndex = 0;
};

} // namespace metal
} // namespace wallpaper
