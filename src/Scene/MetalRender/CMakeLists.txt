if(NOT APPLE)
    return()
endif()

add_library(
  wpMetalRender STATIC
  MetalCustomShaderPass.cpp
  MetalCopyPass.cpp
  MetalPrePass.cpp
  MetalFinPass.cpp
  MetalPassBatch.cpp
  MetalSceneToRenderGraph.cpp
)

target_include_directories(wpMetalRender PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(wpMetalRender PUBLIC wpMetal wpScene wpRGraph)
set_target_properties(wpMetalRender PROPERTIES
  OBJCXX_STANDARD 20
  OBJCXX_STANDARD_REQUIRED YES)
target_compile_options(wpMetalRender PRIVATE
  "$<$<COMPILE_LANGUAGE:OBJCXX>:-fobjc-arc>")
