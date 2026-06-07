#pragma once

#include "../../Metal/MetalDevice.hpp"
#include "../../Metal/MetalResources.hpp"
#include "../Scene.h"
#include <memory>
#include <vector>

namespace wallpaper
{
namespace metal
{

/// Base class for Metal render passes.
class MetalPass {
public:
    virtual ~MetalPass() = default;

    /// Prepares the render pass with scene and device resources.
    virtual void prepare(Scene& scene, MetalDevice& device, MetalRenderingResources& resources) = 0;

    /// Executes the render pass.
    virtual void execute(MetalDevice& device, MetalRenderingResources& resources) = 0;

    /// Destroys the render pass resources.
    virtual void destroy(MetalDevice& device, MetalRenderingResources& resources) = 0;

    /// Returns true if this pass has been prepared.
    bool isPrepared() const { return m_prepared; }

protected:
    bool m_prepared = false;
};

} // namespace metal
} // namespace wallpaper
