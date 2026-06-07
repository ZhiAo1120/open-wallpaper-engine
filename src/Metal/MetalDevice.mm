#include "MetalDevice.hpp"
#include <Metal/Metal.h>

namespace wallpaper
{
namespace metal
{

MetalDevice::MetalDevice()
    : m_device(nil)
    , m_commandQueue(nil) {}

MetalDevice::~MetalDevice() {
    waitIdle();
    m_commandQueue = nil;
    m_device = nil;
}

bool MetalDevice::init(bool prefer_high_performance) {
    // Create Metal device
    if (prefer_high_performance) {
        // Try to get the high-performance GPU (e.g., discrete GPU)
        NSArray<id<MTLDevice>> *devices = MTLCopyAllDevices();
        for (id<MTLDevice> device in devices) {
            if (device.isLowPower == NO) {
                m_device = device;
                break;
            }
        }
    }

    // Fall back to the default device if no high-performance GPU found
    if (m_device == nil) {
        m_device = MTLCreateSystemDefaultDevice();
    }

    if (m_device == nil) {
        return false;
    }

    // Create command queue
    m_commandQueue = [m_device newCommandQueue];
    if (m_commandQueue == nil) {
        m_device = nil;
        return false;
    }

    return true;
}

std::string MetalDevice::deviceName() const {
    if (m_device == nil) return "";
    return [[m_device name] UTF8String];
}

uint64_t MetalDevice::recommendedMaxWorkingSetSize() const {
    if (m_device == nil) return 0;
    return [m_device recommendedMaxWorkingSetSize];
}

bool MetalDevice::supportsMetal2() const {
    if (m_device == nil) return false;
    return [m_device supportsFamily:MTLGPUFamilyApple2] ||
           [m_device supportsFamily:MTLGPUFamilyCommon2] ||
           [m_device supportsFamily:MTLGPUFamilyMac2];
}

bool MetalDevice::supportsArgumentBuffers() const {
    if (m_device == nil) return false;
    return [m_device supportsFamily:MTLGPUFamilyApple1] ||
           [m_device supportsFamily:MTLGPUFamilyCommon1];
}

uint32_t MetalDevice::maxTextureWidth() const {
    if (m_device == nil) return 0;
    return static_cast<uint32_t>([m_device maxTextureWidth]);
}

uint32_t MetalDevice::maxTextureHeight() const {
    if (m_device == nil) return 0;
    return static_cast<uint32_t>([m_device maxTextureHeight]);
}

uint32_t MetalDevice::maxThreadgroupMemoryLength() const {
    if (m_device == nil) return 0;
    return static_cast<uint32_t>([m_device maxThreadgroupMemoryLength]);
}

uint32_t MetalDevice::maxThreadsPerThreadgroup() const {
    if (m_device == nil) return 0;
    MTLSize size = [m_device maxThreadsPerThreadgroup];
    return static_cast<uint32_t>(size.width * size.height * size.depth);
}

void MetalDevice::waitIdle() {
    if (m_device == nil) return;

    // Create a command buffer and wait for completion
    id<MTLCommandBuffer> commandBuffer = [m_commandQueue commandBuffer];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
}

} // namespace metal
} // namespace wallpaper
