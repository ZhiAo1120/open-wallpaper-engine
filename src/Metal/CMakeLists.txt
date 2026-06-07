if(NOT APPLE)
    return()
endif()

add_library(
  wpMetal STATIC
  MetalDevice.mm
  MetalSwapchain.mm
  MetalTextureCache.mm
  MetalStagingBuffer.mm
  MetalShader.mm
  MetalPipeline.mm
)

target_include_directories(wpMetal PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(wpMetal PUBLIC ${METAL_FRAMEWORK} ${QUARTZCORE_FRAMEWORK})
set_target_properties(wpMetal PROPERTIES
  OBJCXX_STANDARD 20
  OBJCXX_STANDARD_REQUIRED YES)
target_compile_options(wpMetal PRIVATE
  "$<$<COMPILE_LANGUAGE:OBJCXX>:-fobjc-arc>")
