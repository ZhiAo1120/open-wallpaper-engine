#include "MetalStagingBuffer.hpp"
#include <cstring>
#include <algorithm>

namespace wallpaper
{
namespace metal
{

// MetalStagingBuffer implementation

MetalStagingBuffer::MetalStagingBuffer()
    : m_device(nil)
    , m_stagingBuffer(nil)
    , m_bufferSize(0)
    , m_currentOffset(0) {}

MetalStagingBuffer::~MetalStagingBuffer() {
    m_stagingBuffer = nil;
    m_device = nil;
}

bool MetalStagingBuffer::init(id<MTLDevice> device, uint64_t initialSize) {
    if (device == nil || initialSize == 0) return false;

    m_device = device;
    m_bufferSize = initialSize;
    m_currentOffset = 0;

    // Create shared staging buffer (CPU visible, GPU readable)
    m_stagingBuffer = [m_device newBufferWithLength:initialSize
                                           options:MTLResourceStorageModeShared];

    return m_stagingBuffer != nil;
}

int64_t MetalStagingBuffer::allocate(uint64_t size) {
    if (size == 0 || m_stagingBuffer == nil) return -1;

    // Align to 256 bytes for Metal buffer alignment requirements
    uint64_t alignedSize = (size + 255) & ~255ULL;

    if (m_currentOffset + alignedSize > m_bufferSize) {
        // Buffer is full
        return -1;
    }

    int64_t offset = static_cast<int64_t>(m_currentOffset);
    m_currentOffset += alignedSize;

    return offset;
}

bool MetalStagingBuffer::write(uint64_t offset, const void* data, uint64_t size) {
    if (m_stagingBuffer == nil || data == nullptr || size == 0) return false;
    if (offset + size > m_bufferSize) return false;

    void* bufferPtr = [m_stagingBuffer contents];
    if (bufferPtr == nullptr) return false;

    std::memcpy(static_cast<uint8_t*>(bufferPtr) + offset, data, size);
    return true;
}

void MetalStagingBuffer::reset() {
    m_currentOffset = 0;
}

void MetalStagingBuffer::commit(
    id<MTLCommandBuffer> commandBuffer,
    id<MTLBuffer> destination,
    uint64_t destinationOffset,
    uint64_t size) {

    if (commandBuffer == nil || destination == nil || m_stagingBuffer == nil) return;
    if (size == 0) return;

    id<MTLBlitCommandEncoder> blitEncoder = [commandBuffer blitCommandEncoder];
    [blitEncoder copyFromBuffer:m_stagingBuffer
                   sourceOffset:0
                       toBuffer:destination
              destinationOffset:destinationOffset
                           size:size];
    [blitEncoder endEncoding];
}

// MetalDoubleStagingBuffer implementation

MetalDoubleStagingBuffer::MetalDoubleStagingBuffer()
    : m_device(nil)
    , m_bufferSize(0)
    , m_currentOffset(0)
    , m_currentIndex(0) {}

MetalDoubleStagingBuffer::~MetalDoubleStagingBuffer() {
    m_buffers.clear();
    m_device = nil;
}

bool MetalDoubleStagingBuffer::init(id<MTLDevice> device, uint64_t initialSize) {
    if (device == nil || initialSize == 0) return false;

    m_device = device;
    m_bufferSize = initialSize;
    m_currentOffset = 0;
    m_currentIndex = 0;

    // Create two staging buffers for double buffering
    m_buffers.clear();
    for (int i = 0; i < 2; ++i) {
        id<MTLBuffer> buffer = [m_device newBufferWithLength:initialSize
                                                    options:MTLResourceStorageModeShared];
        if (buffer == nil) {
            return false;
        }
        m_buffers.push_back(buffer);
    }

    return true;
}

int64_t MetalDoubleStagingBuffer::allocate(uint64_t size) {
    if (size == 0 || m_buffers.empty()) return -1;

    // Align to 256 bytes
    uint64_t alignedSize = (size + 255) & ~255ULL;

    if (m_currentOffset + alignedSize > m_bufferSize) {
        return -1;
    }

    int64_t offset = static_cast<int64_t>(m_currentOffset);
    m_currentOffset += alignedSize;

    return offset;
}

bool MetalDoubleStagingBuffer::write(uint64_t offset, const void* data, uint64_t size) {
    if (m_buffers.empty() || data == nullptr || size == 0) return false;
    if (offset + size > m_bufferSize) return false;

    id<MTLBuffer> buffer = m_buffers[m_currentIndex];
    void* bufferPtr = [buffer contents];
    if (bufferPtr == nullptr) return false;

    std::memcpy(static_cast<uint8_t*>(bufferPtr) + offset, data, size);
    return true;
}

void MetalDoubleStagingBuffer::swap() {
    m_currentIndex = (m_currentIndex + 1) % m_buffers.size();
    m_currentOffset = 0;
}

void MetalDoubleStagingBuffer::commit(
    id<MTLCommandBuffer> commandBuffer,
    id<MTLBuffer> destination,
    uint64_t destinationOffset,
    uint64_t size) {

    if (commandBuffer == nil || destination == nil || m_buffers.empty()) return;
    if (size == 0) return;

    id<MTLBuffer> stagingBuffer = m_buffers[m_currentIndex];

    id<MTLBlitCommandEncoder> blitEncoder = [commandBuffer blitCommandEncoder];
    [blitEncoder copyFromBuffer:stagingBuffer
                   sourceOffset:0
                       toBuffer:destination
              destinationOffset:destinationOffset
                           size:size];
    [blitEncoder endEncoding];
}

} // namespace metal
} // namespace wallpaper
