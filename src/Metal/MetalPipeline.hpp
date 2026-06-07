#pragma once

#include <Metal/Metal.h>
#include "MetalResources.hpp"
#include <string>
#include <unordered_map>
#include <memory>

namespace wallpaper
{
namespace metal
{

/// Cached Metal render pipeline state.
struct MetalPipelineEntry {
    id<MTLRenderPipelineState> pipelineState;
    MetalPipelineConfig config;
    std::string cacheKey;
};

/// Metal render pipeline state management.
class MetalPipeline {
public:
    MetalPipeline();
    ~MetalPipeline();

    /// Initializes the pipeline manager with the given Metal device.
    bool init(id<MTLDevice> device);

    /// Creates a render pipeline state from configuration.
    /// @param config Pipeline configuration.
    /// @param cacheKey Unique key for caching.
    /// @return Pipeline state, or nil on failure.
    id<MTLRenderPipelineState> createPipeline(
        const MetalPipelineConfig& config,
        const std::string& cacheKey);

    /// Queries the cache for an existing pipeline.
    id<MTLRenderPipelineState> query(const std::string& cacheKey) const;

    /// Removes a pipeline from the cache.
    void remove(const std::string& cacheKey);

    /// Clears all cached pipelines.
    void clear();

    /// Returns the number of cached pipelines.
    size_t pipelineCount() const { return m_pipelines.size(); }

    /// Creates a depth stencil state.
    id<MTLDepthStencilState> createDepthStencilState(
        bool depthTestEnabled,
        bool depthWriteEnabled,
        MTLCompareFunction depthCompareFunction = MTLCompareFunctionAlways);

    /// Creates a sampler state.
    id<MTLSamplerState> createSamplerState(
        MTLSamplerMinMagFilter minFilter,
        MTLSamplerMinMagFilter magFilter,
        MTLSamplerMipFilter mipFilter,
        MTLSamplerAddressMode addressMode);

private:
    /// Generates a cache key from pipeline configuration.
    static std::string generateCacheKey(const MetalPipelineConfig& config);

    id<MTLDevice> m_device;
    std::unordered_map<std::string, MetalPipelineEntry> m_pipelines;
};

} // namespace metal
} // namespace wallpaper
