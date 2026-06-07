#pragma once

#include "MetalPass.hpp"
#include "Scene/Scene.h"
#include "RenderGraph/RenderGraph.hpp"
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
};

} // namespace metal
} // namespace wallpaper
