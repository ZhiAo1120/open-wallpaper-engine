#pragma once

#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#include <string>
#include <vector>
#include <cstdint>

namespace wallpaper
{
namespace metal
{

/// Metal device and command queue manager.
class MetalDevice {
public:
    MetalDevice();
    ~MetalDevice();

    /// Initializes the Metal device and command queue.
    /// @param prefer_high_performance If true, prefer high-performance GPU.
    /// @return true on success, false on failure.
    bool init(bool prefer_high_performance = true);

    /// Returns the underlying MTLDevice.
    id<MTLDevice> device() const { return m_device; }

    /// Returns the command queue.
    id<MTLCommandQueue> commandQueue() const { return m_commandQueue; }

    /// Returns the device name.
    std::string deviceName() const;

    /// Returns the recommended max working set size in bytes.
    uint64_t recommendedMaxWorkingSetSize() const;

    /// Returns true if the device supports Metal 2.0+.
    bool supportsMetal2() const;

    /// Returns true if the device supports argument buffers.
    bool supportsArgumentBuffers() const;

    /// Waits for all pending GPU work to complete.
    void waitIdle();

private:
    id<MTLDevice> m_device;
    id<MTLCommandQueue> m_commandQueue;
};

} // namespace metal
} // namespace wallpaper
