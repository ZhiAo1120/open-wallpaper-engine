#pragma once

#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#include <vector>
#include <cstdint>
#include <memory>

namespace wallpaper
{
namespace metal
{

/// Triple-buffered Metal swapchain for presenting to a CAMetalLayer.
class MetalSwapchain {
public:
    MetalSwapchain();
    ~MetalSwapchain();

    /// Initializes the swapchain with the given Metal layer and dimensions.
    /// @param device The Metal device.
    /// @param layer The CAMetalLayer to present to.
    /// @param width The width in pixels.
    /// @param height The height in pixels.
    /// @return true on success, false on failure.
    bool init(id<MTLDevice> device, CAMetalLayer* layer, uint32_t width, uint32_t height);

    /// Resizes the swapchain. Recreates drawables with new dimensions.
    void resize(uint32_t width, uint32_t height);

    /// Acquires the next drawable for rendering.
    /// @return The drawable, or nil if unavailable.
    id<CAMetalDrawable> acquireNextDrawable();

    /// Returns the current drawable's texture.
    id<MTLTexture> currentTexture() const;

    /// Returns the width of the swapchain.
    uint32_t width() const { return m_width; }

    /// Returns the height of the swapchain.
    uint32_t height() const { return m_height; }

    /// Returns the pixel format.
    MTLPixelFormat pixelFormat() const { return m_pixelFormat; }

    /// Returns the number of drawables (triple buffering).
    uint32_t drawableCount() const { return static_cast<uint32_t>(m_drawables.size()); }

private:
    void createDrawables();

    id<MTLDevice> m_device;
    CAMetalLayer* m_layer;
    uint32_t m_width;
    uint32_t m_height;
    MTLPixelFormat m_pixelFormat;
    std::vector<id<CAMetalDrawable>> m_drawables;
    uint32_t m_currentDrawableIndex;
};

} // namespace metal
} // namespace wallpaper
