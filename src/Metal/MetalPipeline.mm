#include "MetalPipeline.hpp"
#include <sstream>
#include <iomanip>

namespace wallpaper
{
namespace metal
{

MetalPipeline::MetalPipeline()
    : m_device(nil) {}

MetalPipeline::~MetalPipeline() {
    clear();
}

bool MetalPipeline::init(id<MTLDevice> device) {
    if (device == nil) return false;
    m_device = device;
    return true;
}

id<MTLRenderPipelineState> MetalPipeline::createPipeline(
    const MetalPipelineConfig& config,
    const std::string& cacheKey) {

    if (m_device == nil || config.vertexFunction == nil || config.fragmentFunction == nil) {
        return nil;
    }

    // Check cache first
    auto it = m_pipelines.find(cacheKey);
    if (it != m_pipelines.end()) {
        return it->second.pipelineState;
    }

    // Create pipeline descriptor
    MTLRenderPipelineDescriptor* desc = [[MTLRenderPipelineDescriptor alloc] init];
    desc.vertexFunction = config.vertexFunction;
    desc.fragmentFunction = config.fragmentFunction;

    // Configure color attachment
    MTLRenderPipelineColorAttachmentDescriptor* colorAttachment =
        desc.colorAttachments[0];
    colorAttachment.pixelFormat = config.colorAttachmentFormat;
    colorAttachment.blendingEnabled = config.blendingEnabled;

    if (config.blendingEnabled) {
        colorAttachment.sourceRGBBlendFactor = config.sourceRGBBlendFactor;
        colorAttachment.destinationRGBBlendFactor = config.destinationRGBBlendFactor;
        colorAttachment.rgbBlendOperation = config.rgbBlendOperation;
        colorAttachment.sourceAlphaBlendFactor = config.sourceAlphaBlendFactor;
        colorAttachment.destinationAlphaBlendFactor = config.destinationAlphaBlendFactor;
        colorAttachment.alphaBlendOperation = config.alphaBlendOperation;
    }

    // Configure depth attachment
    if (config.depthAttachmentFormat != MTLPixelFormatInvalid) {
        desc.depthAttachmentPixelFormat = config.depthAttachmentFormat;
    }

    // Create pipeline state
    NSError* error = nil;
    id<MTLRenderPipelineState> pipelineState =
        [m_device newRenderPipelineStateWithDescriptor:desc error:&error];

    if (pipelineState == nil) {
        NSLog(@"Metal pipeline creation failed: %@", [error localizedDescription]);
        return nil;
    }

    // Cache the pipeline
    MetalPipelineEntry entry;
    entry.pipelineState = pipelineState;
    entry.config = config;
    entry.cacheKey = cacheKey;
    m_pipelines[cacheKey] = entry;

    return pipelineState;
}

id<MTLRenderPipelineState> MetalPipeline::query(const std::string& cacheKey) const {
    auto it = m_pipelines.find(cacheKey);
    if (it != m_pipelines.end()) {
        return it->second.pipelineState;
    }
    return nil;
}

void MetalPipeline::remove(const std::string& cacheKey) {
    m_pipelines.erase(cacheKey);
}

void MetalPipeline::clear() {
    m_pipelines.clear();
}

id<MTLDepthStencilState> MetalPipeline::createDepthStencilState(
    bool depthTestEnabled,
    bool depthWriteEnabled,
    MTLCompareFunction depthCompareFunction) {

    if (m_device == nil) return nil;

    MTLDepthStencilDescriptor* desc = [[MTLDepthStencilDescriptor alloc] init];
    desc.depthWriteEnabled = depthWriteEnabled;

    if (depthTestEnabled) {
        desc.depthCompareFunction = depthCompareFunction;
    } else {
        desc.depthCompareFunction = MTLCompareFunctionAlways;
    }

    return [m_device newDepthStencilStateWithDescriptor:desc];
}

id<MTLSamplerState> MetalPipeline::createSamplerState(
    MTLSamplerMinMagFilter minFilter,
    MTLSamplerMinMagFilter magFilter,
    MTLSamplerMipFilter mipFilter,
    MTLSamplerAddressMode addressMode) {

    if (m_device == nil) return nil;

    MTLSamplerDescriptor* desc = [[MTLSamplerDescriptor alloc] init];
    desc.minFilter = minFilter;
    desc.magFilter = magFilter;
    desc.mipFilter = mipFilter;
    desc.sAddressMode = addressMode;
    desc.tAddressMode = addressMode;
    desc.rAddressMode = addressMode;
    desc.normalizedCoordinates = YES;

    return [m_device newSamplerStateWithDescriptor:desc];
}

std::string MetalPipeline::generateCacheKey(const MetalPipelineConfig& config) {
    std::ostringstream oss;
    oss << "pipeline_";
    oss << std::hex << std::setfill('0');

    // Hash the configuration
    oss << std::setw(8) << (reinterpret_cast<uintptr_t>(config.vertexFunction) & 0xFFFFFFFF);
    oss << std::setw(8) << (reinterpret_cast<uintptr_t>(config.fragmentFunction) & 0xFFFFFFFF);
    oss << "_" << static_cast<uint32_t>(config.colorAttachmentFormat);
    oss << "_" << (config.blendingEnabled ? "blend" : "noblend");

    return oss.str();
}

} // namespace metal
} // namespace wallpaper
