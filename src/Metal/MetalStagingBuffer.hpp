#pragma once

#include <Metal/Metal.h>
#include <cstdint>
#include <vector>
#include <memory>

namespace wallpaper
{
namespace metal
{

/// Double-buffered staging-to-GPU upload mechanism.
class MetalStagingBuffer {
public:
    MetalStagingBuffer();
    ~MetalStagingBuffer();

    /// Initializes the staging buffer.
    /// @param device The Metal device.
    /// @param initialSize Initial buffer size in bytes.
    /// @return true on success, false on failure.
    bool init(id<MTLDevice> device, uint64_t initialSize);

    /// Allocates a sub-region in the staging buffer.
    /// @param size Size in bytes to allocate.
    /// @return Offset from the beginning of the buffer, or -1 on failure.
    int64_t allocate(uint64_t size);

    /// Writes data to the staging buffer at the given offset.
    /// @param offset Offset from the beginning of the buffer.
    /// @param data Data to write.
    /// @param size Size of data in bytes.
    /// @return true on success, false on failure.
    bool write(uint64_t offset, const void* data, uint64_t size);

    /// Returns the current staging buffer.
    id<MTLBuffer> buffer() const { return m_stagingBuffer; }

    /// Returns the current write offset.
    uint64_t currentOffset() const { return m_currentOffset; }

    /// Returns the total buffer size.
    uint64_t size() const { return m_bufferSize; }

    /// Resets the staging buffer for a new frame.
    void reset();

    /// Commits the staging buffer contents to a destination buffer.
    /// @param commandBuffer The command buffer to use for the copy.
    /// @param destination The destination GPU buffer.
    /// @param destinationOffset Offset in the destination buffer.
    /// @param size Number of bytes to copy.
    void commit(
        id<MTLCommandBuffer> commandBuffer,
        id<MTLBuffer> destination,
        uint64_t destinationOffset,
        uint64_t size);

private:
    id<MTLDevice> m_device;
    id<MTLBuffer> m_stagingBuffer;
    uint64_t m_bufferSize;
    uint64_t m_currentOffset;
};

/// Double-buffered staging buffer for continuous upload.
class MetalDoubleStagingBuffer {
public:
    MetalDoubleStagingBuffer();
    ~MetalDoubleStagingBuffer();

    /// Initializes the double-buffered staging buffer.
    bool init(id<MTLDevice> device, uint64_t initialSize);

    /// Allocates a sub-region in the current staging buffer.
    int64_t allocate(uint64_t size);

    /// Writes data to the current staging buffer.
    bool write(uint64_t offset, const void* data, uint64_t size);

    /// Returns the current staging buffer.
    id<MTLBuffer> buffer() const { return m_buffers[m_currentIndex]; }

    /// Returns the current write offset.
    uint64_t currentOffset() const { return m_currentOffset; }

    /// Swaps to the next staging buffer (for double buffering).
    void swap();

    /// Commits the current staging buffer contents to a destination buffer.
    void commit(
        id<MTLCommandBuffer> commandBuffer,
        id<MTLBuffer> destination,
        uint64_t destinationOffset,
        uint64_t size);

private:
    id<MTLDevice> m_device;
    std::vector<id<MTLBuffer>> m_buffers;
    uint64_t m_bufferSize;
    uint64_t m_currentOffset;
    uint32_t m_currentIndex;
};

} // namespace metal
} // namespace wallpaper
