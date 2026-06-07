if(NOT APPLE)
    return()
endif()

add_library(
  wpMetalRender STATIC
  MetalCustomShaderPass.mm
  MetalCopyPass.mm
  MetalPrePass.mm
  MetalFinPass.mm
  MetalPassBatch.mm
  MetalSceneToRenderGraph.mm
  MetalRender.mm
)

target_include_directories(wpMetalRender PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(wpMetalRender PUBLIC wpMetal wpScene wpRGraph)
set_target_properties(wpMetalRender PROPERTIES
  OBJCXX_STANDARD 20
  OBJCXX_STANDARD_REQUIRED YES)
target_compile_options(wpMetalRender PRIVATE
  "$<$<COMPILE_LANGUAGE:OBJCXX>:-fobjc-arc>")
