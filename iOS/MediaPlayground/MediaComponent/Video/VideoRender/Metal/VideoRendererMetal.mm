//
//  VideoRendererMetal.m
//  MediaPlayground
//
//  Created by Viva on 2025/4/12.
//

#import "VideoRendererMetal.h"
#import "MetalGlobalRecource.h"
#import "MetalDisplayView.h"
#import "MetalTexture.h"
#import "MetalShaderDefine.h"

#import <Metal/Metal.h>
#include <vector>

const float MetalDefaultVertexCoordinates[] = {
    -1.0f, 1.0f,// 左上
    -1.0f, -1.0f,// 左下
    1.0f, 1.0f,// 右上
    1.0f, -1.0f// 右下
};

const float MetalDefaultTextureCoordinates[] = {
    0.0f, 0.0f,// 左上
    0.0f, 1.0f,// 左下
    1.0f, 0.0f,// 右上
    1.0f, 1.0f// 右下
};

static const NSUInteger kMaxTextureCount = 3;

@interface VideoRendererMetal ()

@property (nonatomic, strong) MetalDisplayView* display_view;
@property (nonatomic, strong) id<MTLRenderPipelineState> render_pipeline_state;

@end

@implementation VideoRendererMetal {
  CVMetalTextureCacheRef texture_cache_;
  std::vector<MetalTexture*> texture_list_;
}

- (void)dealloc {
  NSLog(@"%s", __PRETTY_FUNCTION__);
  
  [self.display_view removeFromSuperview];
  
  CFRelease(texture_cache_);
  
  for (int i = 0; i < kMaxTextureCount; i++) {
    delete texture_list_[i];
    texture_list_[i] = nullptr;
  }
}

- (instancetype)init {
  self = [super init];
  if (self) {
    [self prepareRenderResource];
  }
  return self;
}

#pragma mark - Public

- (void)attachNativeView:(UIView*)native_view {
  self.display_view = [[MetalDisplayView alloc] initWithFrame:native_view.bounds];
  [native_view addSubview:self.display_view];
}

- (void)renderVideoFrameWithData:(void*)data width:(NSUInteger)width height:(NSUInteger)height {
  [self updateTextureWithData:data width:width height:height];
  [self renderWithWidth:width height:height];
}

- (void)renderVideoFrameWithPixelBuffer:(CVPixelBufferRef)pixel_buffer width:(NSUInteger)width height:(NSUInteger)height {
  [self updateTextureWithPixelBuffer:pixel_buffer width:width height:height];
  [self renderWithWidth:width height:height];
}

#pragma mark - Function

- (void)prepareRenderResource {
  // resource
  id<MTLDevice> device = [[MetalGlobalRecource sharedInstance] getDevice];
  id<MTLLibrary> default_library = [[MetalGlobalRecource sharedInstance] getDefaultLibrary];
  
  // texture
  CVMetalTextureCacheCreate(kCFAllocatorDefault, NULL, device, NULL, &texture_cache_);
  for (int i = 0; i < kMaxTextureCount; i++) {
    MetalTexture* texture = new MetalTexture();
    texture->Init(VideoRenderPixelDataTypePlatformRelated, texture_cache_, device);
//    texture->Init(VideoRenderPixelDataTypeUniversal, texture_cache_, device);
    texture_list_.push_back(texture);
  }
  
  // shader
  id<MTLFunction> vertex_function = [default_library newFunctionWithName:@"BasicVertexShader"];// from MetalBaseShader.metal
  id<MTLFunction> fragment_function = [default_library newFunctionWithName:@"NV12FragmentShader"];// from MetalBaseShader.metal
  MTLRenderPipelineDescriptor* pipeline_descriptor = [[MTLRenderPipelineDescriptor alloc] init];
  pipeline_descriptor.vertexFunction = vertex_function;
  pipeline_descriptor.fragmentFunction = fragment_function;
  pipeline_descriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
  NSError* error = nil;
  self.render_pipeline_state = [device newRenderPipelineStateWithDescriptor:pipeline_descriptor error:&error];
  if (error) {
    NSAssert(!error, @"init shader failed, error:%@", error);
  }
}

- (void)updateTextureWithData:(void*)data width:(NSUInteger)width height:(NSUInteger)height {
  uint32_t offset = (uint32_t)(width * height);
  texture_list_[0]->UpdateData(VideoRenderTextureFormatLuminance, (uint32_t)width, (uint32_t)height, data, 0);
  texture_list_[1]->UpdateData(VideoRenderTextureFormatLuminanceAlpha, (uint32_t)width, (uint32_t)height, data, offset);
}

- (void)updateTextureWithPixelBuffer:(CVPixelBufferRef)pixel_buffer width:(NSUInteger)width height:(NSUInteger)height {
  texture_list_[0]->UpdateData(VideoRenderTextureFormatLuminance, (uint32_t)width, (uint32_t)height, pixel_buffer, 0);
  texture_list_[1]->UpdateData(VideoRenderTextureFormatLuminanceAlpha, (uint32_t)width, (uint32_t)height, pixel_buffer, 0);
}

- (void)renderWithWidth:(NSUInteger)width height:(NSUInteger)height {
  // resource
  id<MTLDevice> device = [[MetalGlobalRecource sharedInstance] getDevice];
  id<MTLCommandBuffer> command_buffer = [[[MetalGlobalRecource sharedInstance] getCommandQueue] commandBuffer];
  id<CAMetalDrawable> drawable = [[self.display_view getMetalLayer] nextDrawable];
  
  // prepare render target
  id<MTLTexture> target_texture = drawable.texture;
  MTLRenderPassDescriptor* render_pass_descriptor = [MTLRenderPassDescriptor renderPassDescriptor];
  render_pass_descriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0f, 0.0f, 0.0f, 1.0f);
  render_pass_descriptor.colorAttachments[0].texture = target_texture;
  render_pass_descriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
  render_pass_descriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
  //
  id<MTLRenderCommandEncoder> render_command_encoder = [command_buffer renderCommandEncoderWithDescriptor:render_pass_descriptor];
  [render_command_encoder setViewport:(MTLViewport){0.0f, 0.0f, [self.display_view getMetalLayer].drawableSize.width, [self.display_view getMetalLayer].drawableSize.height, 0.0f, 1.0f}];
  
  // bind shader
  [render_command_encoder setRenderPipelineState:self.render_pipeline_state];
  
  // bind texture with shader
  [render_command_encoder setFragmentTexture:texture_list_[0]->GetTexture() atIndex:MetalShaderTextureIndex0];
  [render_command_encoder setFragmentTexture:texture_list_[1]->GetTexture() atIndex:MetalShaderTextureIndex1];
  
  // bind vertex coordinates with shader
  id<MTLBuffer> vertex_coordinates_buffer = [device newBufferWithBytes:MetalDefaultVertexCoordinates length:sizeof(MetalDefaultVertexCoordinates) options:MTLResourceStorageModeShared];
  [render_command_encoder setVertexBuffer:vertex_coordinates_buffer offset:0 atIndex:MetalShaderIndexVertexCoordinates];
  
  // bind texture coordinates with shader
  id<MTLBuffer> texture_coordinates_buffer = [device newBufferWithBytes:MetalDefaultTextureCoordinates length:sizeof(MetalDefaultTextureCoordinates) options:MTLResourceStorageModeShared];
  [render_command_encoder setVertexBuffer:texture_coordinates_buffer offset:0 atIndex:MetalShaderIndexTextureCoordinates];
  
  // render
  [render_command_encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
  [render_command_encoder endEncoding];
  
  // show render result on screen
  [command_buffer presentDrawable:drawable];
  
  // commit render commands
  [command_buffer commit];
  [command_buffer waitUntilCompleted];
}

@end
