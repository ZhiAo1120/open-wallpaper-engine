#pragma once

#include "MetalCustomShaderPass.hpp"
#include "MetalCopyPass.hpp"
#include "../Scene.h"
#include "../RenderGraph/RenderGraph.hpp"
#include <memory>
#include <vector>

namespace wallpaper
{
namespace metal
{

/// Converts a scene graph to a Metal render graph.
class MetalSceneToRenderGraph {
public:
    /// Converts the scene to a render graph.
    /// @param scene The scene to convert.
    /// @param renderGraph The render graph to populate.
    static void convert(
        Scene& scene,
        rg::RenderGraph& renderGraph);

private:
    /// Processes a scene node and its children.
    static void processNode(
        SceneNode* node,
        Scene& scene,
        rg::RenderGraph& renderGraph);

    /// Creates a custom shader pass from a scene object.
    static std::unique_ptr<MetalCustomShaderPass> createCustomShaderPass(
        SceneObject* object,
        Scene& scene);

    /// Creates a copy pass from a scene object.
    static std::unique_ptr<MetalCopyPass> createCopyPass(
        SceneObject* object,
        Scene& scene);
};

} // namespace metal
} // namespace wallpaper
