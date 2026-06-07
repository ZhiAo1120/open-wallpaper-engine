#include "MetalSwapchain.hpp"

namespace wallpaper
{
namespace metal
{

MetalSwapchain::MetalSwapchain()
    : m_device(nil)
    , m_layer(nullptr)
    , m_width(0)
    , m_height(0)
    , m_pixelFormat(MTLPixelFormatBGRA8Unorm)
    , m_currentDrawableIndex(0) {}

MetalSwapchain::~MetalSwapchain() {
    m_drawables.clear();
}

bool MetalSwapchain::init(id<MTLDevice> device, CAMetalLayer* layer, uint32_t width, uint32_t height) {
    if (device == nil || layer == nullptr || width == 0 || height == 0) {
        return false;
    }

    m_device = device;
    m_layer = layer;
    m_width = width;
    m_height = height;

    // Configure the Metal layer
    m_layer.device = m_device;
    m_layer.pixelFormat = m_pixelFormat;
    m_layer.framebufferOnly = YES; // Optimize for presentation
    m_layer.drawableSize = CGSizeMake(width, height);

    // Enable triple buffering
    m_layer.maximumDrawableCount = 3;

    // Create drawables
    createDrawables();

    return true;
}

void MetalSwapchain::resize(uint32_t width, uint32_t height) {
    if (width == 0 || height == 0) return;

    m_width = width;
    m_height = height;

    // Update layer drawable size
    m_layer.drawableSize = CGSizeMake(width, height);

    // Recreate drawables with new size
    m_drawables.clear();
    m_currentDrawableIndex = 0;
    createDrawables();
}

id<CAMetalDrawable> MetalSwapchain::acquireNextDrawable() {
    if (m_drawables.empty()) {
        return nil;
    }

    // Get the next drawable
    id<CAMetalDrawable> drawable = m_drawables[m_currentDrawableIndex];
    m_currentDrawableIndex = (m_currentDrawableIndex + 1) % m_drawables.size();

    return drawable;
}

id<MTLTexture> MetalSwapchain::currentTexture() const {
    if (m_drawables.empty()) return nil;

    uint32_t prevIndex = (m_currentDrawableIndex + m_drawables.size() - 1) % m_drawables.size();
    return m_drawables[prevIndex].texture;
}

void MetalSwapchain::createDrawables() {
    m_drawables.clear();

    // Pre-create drawables for triple buffering
    for (uint32_t i = 0; i < 3; ++i) {
        id<CAMetalDrawable> drawable = [m_layer nextDrawable];
        if (drawable != nil) {
            m_drawables.push_back(drawable);
        }
    }

    // If we couldn't get 3 drawables, try with fewer
    if (m_drawables.empty()) {
        id<CAMetalDrawable> drawable = [m_layer nextDrawable];
        if (drawable != nil) {
            m_drawables.push_back(drawable);
        }
    }
}

} // namespace metal
} // namespace wallpaper
