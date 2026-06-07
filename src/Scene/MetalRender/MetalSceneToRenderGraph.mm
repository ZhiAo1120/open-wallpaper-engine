#include "MetalSceneToRenderGraph.hpp"
#include "MetalCustomShaderPass.hpp"
#include "MetalCopyPass.hpp"

namespace wallpaper
{
namespace metal
{

void MetalSceneToRenderGraph::convert(
    Scene& scene,
    rg::RenderGraph& renderGraph) {

    // TODO: Implement scene to render graph conversion
    // This is a placeholder for the actual implementation
    // The Vulkan version uses sceneToRenderGraph() which traverses the scene graph
    // and creates CustomShaderPass and CopyPass nodes

    (void)scene;
    (void)renderGraph;
}

} // namespace metal
} // namespace wallpaper
