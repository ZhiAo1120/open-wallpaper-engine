#pragma once

#include "MetalPass.hpp"
#include <vector>

namespace wallpaper
{
namespace metal
{

/// Render pass batch - groups compatible passes for shared render pass sessions.
struct MetalPassBatch {
    /// Passes in this batch.
    std::vector<MetalPass*> passes;

    /// Shared render target for this batch.
    id<MTLTexture> renderTarget = nil;

    /// Render target dimensions.
    uint32_t width = 0;
    uint32_t height = 0;

    /// MSAA sample count.
    uint32_t sampleCount = 1;

    /// Clear value for the render target.
    double clearValue[4]; // Use double array instead of MTLClearValue

    /// Whether to clear the render target on first use.
    bool clearOnFirstUse = false;

    /// Whether to preserve target contents.
    bool preserveTargetContents = false;
};

/// Plans render pass batches for compatible passes.
class MetalPassBatchPlanner {
public:
    /// Plans batches for the given passes.
    /// @param passes List of render passes to batch.
    /// @return List of planned batches.
    static std::vector<MetalPassBatch> planBatches(
        const std::vector<MetalPass*>& passes);
};

} // namespace metal
} // namespace wallpaper
