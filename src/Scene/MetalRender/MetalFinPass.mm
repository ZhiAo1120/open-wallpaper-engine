#include "MetalFinPass.hpp"

namespace wallpaper
{
namespace metal
{

MetalFinPass::MetalFinPass(const Desc& desc)
    : m_desc(desc) {}

MetalFinPass::~MetalFinPass() {
    // Resources should be destroyed before destruction
}

void MetalFinPass::prepare(Scene& scene, MetalDevice& device, MetalRenderingResources& resources) {
    if (m_prepared) return;

    // Create pipeline for fullscreen quad rendering
    createPipeline(device);

    // Create vertex buffer for fullscreen quad
    createVertexBuffer(device);

    m_prepared = true;
}

void MetalFinPass::execute(MetalDevice& device, MetalRenderingResources& resources) {
    if (!m_prepared || resources.commandBuffer == nil) return;

    // Create render pass descriptor for final blit
    MTLRenderPassDescriptor* renderPassDesc = [[MTLRenderPassDescriptor alloc] init];
    renderPassDesc.colorAttachments[0].texture = m_desc.destinationTexture;
    renderPassDesc.colorAttachments[0].loadAction = MTLLoadActionDontCare;
    renderPassDesc.colorAttachments[0].storeAction = MTLStoreActionStore;

    // Create render command encoder
    id<MTLRenderCommandEncoder> renderEncoder =
        [resources.commandBuffer renderCommandEncoderWithDescriptor:renderPassDesc];

    // Set pipeline state
    if (m_pipelineState != nil) {
        [renderEncoder setRenderPipelineState:m_pipelineState];
    }

    // Set viewport
    [renderEncoder setViewport:m_desc.viewport];

    // Set scissor rect
    [renderEncoder setScissorRect:m_desc.scissor];

    // Bind vertex buffer
    if (m_vertexBuffer != nil) {
        [renderEncoder setVertexBuffer:m_vertexBuffer offset:0 atIndex:0];
    }

    // Bind source texture (default render target)
    if (m_desc.sourceTexture != nil) {
        [renderEncoder setFragmentTexture:m_desc.sourceTexture atIndex:0];
    }

    // Draw fullscreen quad (4 vertices)
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];

    // End encoding
    [renderEncoder endEncoding];
}

void MetalFinPass::destroy(MetalDevice& device, MetalRenderingResources& resources) {
    m_pipelineState = nil;
    m_vertexBuffer = nil;
    m_desc.sourceTexture = nil;
    m_desc.destinationTexture = nil;
    m_prepared = false;
}

void MetalFinPass::createPipeline(MetalDevice& device) {
    if (device.device() == nil) return;

    // MSL source for fullscreen quad vertex shader
    NSString* vertexSource = @""
        "#include <metal_stdlib>\n"
        "using namespace metal;\n"
        "struct VertexIn {\n"
        "    float2 position [[attribute(0)]];\n"
        "    float2 texCoord [[attribute(1)]];\n"
        "};\n"
        "struct VertexOut {\n"
        "    float4 position [[position]];\n"
        "    float2 texCoord;\n"
        "};\n"
        "vertex VertexOut vertexShader(const VertexIn in [[stage_in]]) {\n"
        "    VertexOut out;\n"
        "    out.position = float4(in.position, 0.0, 1.0);\n"
        "    out.texCoord = in.texCoord;\n"
        "    return out;\n"
        "}\n";

    // MSL source for fullscreen quad fragment shader
    NSString* fragmentSource = @""
        "#include <metal_stdlib>\n"
        "using namespace metal;\n"
        "struct VertexOut {\n"
        "    float4 position [[position]];\n"
        "    float2 texCoord;\n"
        "};\n"
        "fragment float4 fragmentShader(VertexOut in [[stage_in]],\n"
        "                               texture2d<float> tex [[texture(0)]],\n"
        "                               sampler s [[sampler(0)]]) {\n"
        "    return tex.sample(s, in.texCoord);\n"
        "}\n";

    // Compile vertex shader
    NSError* error = nil;
    MTLCompileOptions* options = [[MTLCompileOptions alloc] init];
    options.languageVersion = MTLLanguageVersion2_0;

    id<MTLLibrary> vertexLib = [device.device() newLibraryWithSource:vertexSource
                                                            options:options
                                                              error:&error];
    if (vertexLib == nil) {
        NSLog(@"Metal vertex shader compilation failed: %@", [error localizedDescription]);
        return;
    }

    id<MTLFunction> vertexFunc = [vertexLib newFunctionWithName:@"vertexShader"];
    if (vertexFunc == nil) {
        return;
    }

    // Compile fragment shader
    id<MTLLibrary> fragmentLib = [device.device() newLibraryWithSource:fragmentSource
                                                             options:options
                                                               error:&error];
    if (fragmentLib == nil) {
        NSLog(@"Metal fragment shader compilation failed: %@", [error localizedDescription]);
        return;
    }

    id<MTLFunction> fragmentFunc = [fragmentLib newFunctionWithName:@"fragmentShader"];
    if (fragmentFunc == nil) {
        return;
    }

    // Create pipeline descriptor
    MTLRenderPipelineDescriptor* pipelineDesc = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDesc.vertexFunction = vertexFunc;
    pipelineDesc.fragmentFunction = fragmentFunc;
    pipelineDesc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;

    // Create pipeline state
    error = nil;
    m_pipelineState = [device.device() newRenderPipelineStateWithDescriptor:pipelineDesc
                                                                  error:&error];
    if (m_pipelineState == nil) {
        NSLog(@"Metal pipeline creation failed: %@", [error localizedDescription]);
    }
}

void MetalFinPass::createVertexBuffer(MetalDevice& device) {
    if (device.device() == nil) return;

    // Define fullscreen quad vertices (position + texture coordinates)
    struct Vertex {
        float position[2];
        float texCoord[2];
    };

    // Standard fullscreen quad
    Vertex vertices[] = {
        {{-1.0f, -1.0f}, {0.0f, 1.0f}},  // Bottom-left
        {{ 1.0f, -1.0f}, {1.0f, 1.0f}},  // Bottom-right
        {{-1.0f,  1.0f}, {0.0f, 0.0f}},  // Top-left
        {{ 1.0f,  1.0f}, {1.0f, 0.0f}},  // Top-right
    };

    // Flip horizontally if needed
    if (m_desc.horizontalFlip) {
        for (auto& vertex : vertices) {
            vertex.texCoord[0] = 1.0f - vertex.texCoord[0];
        }
    }

    // Create vertex buffer
    m_vertexBuffer = [device.device() newBufferWithBytes:vertices
                                                length:sizeof(vertices)
                                               options:MTLResourceStorageModeShared];
}

} // namespace metal
} // namespace wallpaper
