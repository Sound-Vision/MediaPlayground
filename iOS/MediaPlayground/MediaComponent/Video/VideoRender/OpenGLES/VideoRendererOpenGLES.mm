//
//  VideoRendererOpenGLES.m
//  MediaPlayground
//
//  Created by Viva on 2025/1/11.
//

#import "VideoRendererOpenGLES.h"
#import "VideoRenderDefine.h"
#import "OpenGLESDisplayView.h"
#include "OpenGLESTexture.h"
#include "OpenGLESShaderProgram.h"

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/EAGL.h>
#include <vector>

#define QUICK_STRING(text) #text

static const float OpenGLESDefaultVertexCoordinates[] = {
  -1.0f, 1.0f,// 左上
  -1.0f, -1.0f,// 左下
  1.0f, 1.0f,// 右上
  1.0f, -1.0f// 右下
};

static const float OpenGLESDefaultTextureCoordinates[] = {
  0.0f, 1.0f,// 左上
  0.0f, 0.0f,// 左下
  1.0f, 1.0f,// 右上
  1.0f, 0.0f// 右下
};

static const char OpenGLESDefaultVertexShader[] = QUICK_STRING
(
 attribute vec4 vertex_coordinates;
 attribute vec4 texture_coordinates;
 varying vec4 passed_texture_coordinates;

 void main()
 {
  gl_Position = vertex_coordinates;
  passed_texture_coordinates = texture_coordinates;
 }
);

static const char OpenGLESDefaultFragmentShaderString[] = QUICK_STRING
(
 precision mediump float;
 
 uniform sampler2D input_texture_0;
 varying vec4 passed_texture_coordinates;

 void main()
 {
    gl_FragColor = texture2D(input_texture_0, passed_texture_coordinates.xy);
 }
);

static const char OpenGLESFragmentShaderNV12[] = QUICK_STRING
(
 precision mediump float;
 
 uniform sampler2D input_texture_0;
 uniform sampler2D input_texture_1;
 varying vec4 passed_texture_coordinates;
 
 vec3 YUVToRGB(float y, float u, float v)
 {
    float r;
    float g;
    float b;
    
    y = 1.1643 * (y - 0.0625);
    u = u - 0.5;
    v = v - 0.5;
    
    r = y + 1.5958 * v;
    g = y - 0.39173 * u - 0.81290 * v;
    b = y + 2.017 * u;
    
    return vec3(r, g, b);
 }
 
 void main()
 {
    float y = texture2D(input_texture_0, passed_texture_coordinates.xy).r;
    float u = texture2D(input_texture_1, passed_texture_coordinates.xy).r;
    float v = texture2D(input_texture_1, passed_texture_coordinates.xy).a;
    
    vec3 rgb = YUVToRGB(y, u, v);
    
    gl_FragColor = vec4(rgb, 1.0);
 }
);

static const NSUInteger kMaxTextureCount = 3;

@interface VideoRendererOpenGLES()

@property (nonatomic, strong) OpenGLESDisplayView* display_view;
@property (nonatomic, strong) EAGLContext* gl_context;

@end

@implementation VideoRendererOpenGLES {
  // texture
  CVOpenGLESTextureCacheRef texture_cache_;
  std::vector<OpenGLESTexture*> texture_list_;
  
  // shader
  OpenGLESShaderProgram* shader_program_;
  int vertex_coordinates_attribute_index_;
  int texture_coordinates_attribute_index_;
}

- (void)dealloc {
  NSLog(@"%s", __PRETTY_FUNCTION__);
  
  [self.display_view removeFromSuperview];
  
  CFRelease(texture_cache_);
  
  for (int i = 0; i < kMaxTextureCount; i++) {
    delete texture_list_[i];
    texture_list_[i] = nullptr;
  }
  
  if (shader_program_) {
    delete shader_program_;
    shader_program_ = nullptr;
  }
}

- (instancetype)init {
  self = [super init];
  if (self) {
    [self prepareRenderResource];
  }
  return self;
}

- (void)prepareRenderResource {
  self.gl_context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  
  [EAGLContext setCurrentContext:self.gl_context];
  
  // texture
  CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.gl_context, NULL, &texture_cache_);
  for (int i = 0; i < kMaxTextureCount; i++) {
    OpenGLESTexture* texture = new OpenGLESTexture();
    texture->Init(VideoRenderPixelDataTypePlatformRelated, texture_cache_);
    texture_list_.push_back(texture);
  }
  
  // shader
  shader_program_ = new OpenGLESShaderProgram();
  shader_program_->InitShader(OpenGLESDefaultVertexShader, OpenGLESFragmentShaderNV12);
  shader_program_->GetAttribLocation("vertex_coordinates", &vertex_coordinates_attribute_index_);
  shader_program_->GetAttribLocation("texture_coordinates", &texture_coordinates_attribute_index_);
}

- (void)attachNativeView:(UIView*)native_view {
  self.display_view = [[OpenGLESDisplayView alloc] initWithFrame:native_view.bounds context:self.gl_context];
  [native_view addSubview:self.display_view];
}

- (void)renderVideoFrameWithData:(void*)data width:(NSUInteger)width height:(NSUInteger)height {
  
}

- (void)renderVideoFrameWithPixelBuffer:(CVPixelBufferRef)pixel_buffer width:(NSUInteger)width height:(NSUInteger)height {
  // bind context
  [EAGLContext setCurrentContext:self.gl_context];
  
  // prepare texture
  texture_list_[0]->UpdateData(VideoRenderTextureFormatLuminance, width, height, pixel_buffer, 0);// Y
  texture_list_[1]->UpdateData(VideoRenderTextureFormatLuminanceAlpha, width, height, pixel_buffer, 0);// UV
  
  // prepare render target
  GLint frame_buffer_id_old = 0;
  glGetIntegerv(GL_FRAMEBUFFER_BINDING, &frame_buffer_id_old);
  
  GLint frame_buffer_id = [self.display_view getFrameBufferId];
  glBindFramebuffer(GL_FRAMEBUFFER, frame_buffer_id);
  
  glViewport(0, 0, [self.display_view getBackingWidth], [self.display_view getBackingHeight]);
  glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);
  
  // start shader program
  shader_program_->StartProgram();
  
  // put texture data into shader
  shader_program_->SetTexture("input_texture_0", 0, texture_list_[0]->GetTextureId());
  shader_program_->SetTexture("input_texture_1", 1, texture_list_[1]->GetTextureId());
  
  // put vertex coordinate data into shader
  GLuint vertex_coordinates_buffer_id = 0;
  glGenBuffers(1, &vertex_coordinates_buffer_id);
  glBindBuffer(GL_ARRAY_BUFFER, vertex_coordinates_buffer_id);
  glBufferData(GL_ARRAY_BUFFER, 4*2*sizeof(float_t), OpenGLESDefaultVertexCoordinates, GL_STATIC_DRAW);
  glVertexAttribPointer(vertex_coordinates_attribute_index_, 2, GL_FLOAT, GL_FALSE, 2*sizeof(float), NULL);
  glEnableVertexAttribArray(vertex_coordinates_attribute_index_);
  
  // reverse texture coordiantes for screen display
  float texture_coordiantes[8];
  memcpy(texture_coordiantes, OpenGLESDefaultTextureCoordinates, sizeof(float)*8);
  texture_coordiantes[1] = OpenGLESDefaultTextureCoordinates[3];
  texture_coordiantes[3] = OpenGLESDefaultTextureCoordinates[1];
  texture_coordiantes[5] = OpenGLESDefaultTextureCoordinates[7];
  texture_coordiantes[7] = OpenGLESDefaultTextureCoordinates[5];
  
  // put texture coordinate data into shader
  GLuint texture_coordinates_buffer_id = 0;
  glGenBuffers(1, &texture_coordinates_buffer_id);
  glBindBuffer(GL_ARRAY_BUFFER, texture_coordinates_buffer_id);
  glBufferData(GL_ARRAY_BUFFER, 4*2*sizeof(float_t), texture_coordiantes, GL_STATIC_DRAW);
  glVertexAttribPointer(texture_coordinates_attribute_index_, 2, GL_FLOAT, GL_FALSE, 2*sizeof(float), NULL);
  glEnableVertexAttribArray(texture_coordinates_attribute_index_);
  
  // render
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  
  // stop shader program
  shader_program_->StopProgram();
  
  // clear resource
  glDeleteBuffers(1, &vertex_coordinates_buffer_id);
  glDeleteBuffers(1, &texture_coordinates_buffer_id);
  glBindFramebuffer(GL_FRAMEBUFFER, frame_buffer_id_old);
  
  [self.gl_context presentRenderbuffer:GL_RENDERBUFFER];
}

@end
