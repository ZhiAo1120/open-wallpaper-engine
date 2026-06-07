#include "MetalPassBatch.hpp"
#include "MetalCustomShaderPass.hpp"
#include <algorithm>

namespace wallpaper
{
namespace metal
{

std::vector<MetalPassBatch> MetalPassBatchPlanner::planBatches(
    const std::vector<MetalPass*>& passes) {

    std::vector<MetalPassBatch> batches;

    // Simple batching strategy: group consecutive CustomShaderPass instances
    // that target the same render target
    MetalPassBatch currentBatch;
    id<MTLTexture> currentRenderTarget = nil;

    for (auto* pass : passes) {
        auto* customShaderPass = dynamic_cast<MetalCustomShaderPass*>(pass);

        if (customShaderPass != nil) {
            // Check if this pass can be batched with the current batch
            id<MTLTexture> passRenderTarget = customShaderPass->desc().outputTexture;

            if (currentRenderTarget == nil || currentRenderTarget == passRenderTarget) {
                // Add to current batch
                currentBatch.passes.push_back(pass);
                currentRenderTarget = passRenderTarget;
            } else {
                // Start a new batch
                if (!currentBatch.passes.empty()) {
                    currentBatch.renderTarget = currentRenderTarget;
                    batches.push_back(currentBatch);
                }

                // Reset current batch
                currentBatch = MetalPassBatch();
                currentBatch.passes.push_back(pass);
                currentRenderTarget = passRenderTarget;
            }
        } else {
            // Non-CustomShaderPass instances start a new batch
            if (!currentBatch.passes.empty()) {
                currentBatch.renderTarget = currentRenderTarget;
                batches.push_back(currentBatch);
            }

            // Create a single-pass batch
            MetalPassBatch singleBatch;
            singleBatch.passes.push_back(pass);
            batches.push_back(singleBatch);

            // Reset current batch
            currentBatch = MetalPassBatch();
            currentRenderTarget = nil;
        }
    }

    // Add the last batch if not empty
    if (!currentBatch.passes.empty()) {
        currentBatch.renderTarget = currentRenderTarget;
        batches.push_back(currentBatch);
    }

    return batches;
}

} // namespace metal
} // namespace wallpaper
