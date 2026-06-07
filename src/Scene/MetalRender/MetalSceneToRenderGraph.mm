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

    // Process the scene root node
    if (scene.rootNode != nullptr) {
        processNode(scene.rootNode, scene, renderGraph);
    }
}

void MetalSceneToRenderGraph::processNode(
    SceneNode* node,
    Scene& scene,
    rg::RenderGraph& renderGraph) {

    if (node == nullptr) return;

    // Process objects attached to this node
    for (auto* object : node->objects) {
        if (object == nullptr) continue;

        // Check object type and create appropriate render pass
        switch (object->type) {
            case SceneObjectType::CustomShader: {
                auto pass = createCustomShaderPass(object, scene);
                if (pass != nullptr) {
                    // TODO: Add pass to render graph
                    // renderGraph.addPass(std::move(pass));
                }
                break;
            }
            case SceneObjectType::Copy: {
                auto pass = createCopyPass(object, scene);
                if (pass != nullptr) {
                    // TODO: Add pass to render graph
                    // renderGraph.addPass(std::move(pass));
                }
                break;
            }
            default:
                // Unsupported object type
                break;
        }
    }

    // Process child nodes recursively
    for (auto* child : node->children) {
        processNode(child, scene, renderGraph);
    }
}

std::unique_ptr<MetalCustomShaderPass> MetalSceneToRenderGraph::createCustomShaderPass(
    SceneObject* object,
    Scene& scene) {

    // Create custom shader pass descriptor
    MetalCustomShaderPass::Desc desc;
    desc.node = object->node;
    desc.materialSlot = object->materialSlot;

    // TODO: Populate textures, output, and other properties from scene object

    return std::make_unique<MetalCustomShaderPass>(desc);
}

std::unique_ptr<MetalCopyPass> MetalSceneToRenderGraph::createCopyPass(
    SceneObject* object,
    Scene& scene) {

    // Create copy pass descriptor
    MetalCopyPass::Desc desc;

    // TODO: Populate source and destination from scene object

    return std::make_unique<MetalCopyPass>(desc);
}

} // namespace metal
} // namespace wallpaper
