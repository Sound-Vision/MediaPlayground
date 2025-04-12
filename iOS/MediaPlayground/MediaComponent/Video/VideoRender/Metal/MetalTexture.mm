//
//  MetalTexture.cpp
//  
//
//  Created by Viva on 2023/8/12.
//

#include "MetalTexture.h"

#include <Metal/Metal.h>

MetalTexture::MetalTexture() {
  
}

MetalTexture::~MetalTexture() {
  texture_cache_ = NULL;
  metal_device_ = nil;
  texture_ = nil;
}

void MetalTexture::Init(VideoRenderPixelDataType data_type, CVMetalTextureCacheRef texture_cache, id<MTLDevice> metal_device) {
  data_type_ = data_type;
  texture_cache_ = texture_cache;
  metal_device_ = metal_device;
}

void MetalTexture::UpdateData(VideoRenderTextureFormat format, uint32_t pixel_width, uint32_t pixel_height, void* data, uint32_t offset) {
  MTLTextureDescriptor* descriptor = [[MTLTextureDescriptor alloc] init];
  descriptor.width = pixel_width;
  descriptor.height = pixel_height;
  
  if (data_type_ == VideoRenderPixelDataTypePlatformRelated) {
    CVPixelBufferRef pixel_buffer = (CVPixelBufferRef)data;
    
    CVPixelBufferRetain(pixel_buffer);
    CVPixelBufferLockBaseAddress(pixel_buffer, 0);
    
    switch (format) {
      case VideoRenderTextureFormatLuminance: {
        CVMetalTextureRef cv_texture = nullptr;
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, texture_cache_, pixel_buffer, NULL, MTLPixelFormatR8Unorm, pixel_width, pixel_height, 0, &cv_texture);
        texture_ = CVMetalTextureGetTexture(cv_texture);
        CFRelease(cv_texture);
        break;
      }
      case VideoRenderTextureFormatLuminanceAlpha: {
        CVMetalTextureRef cv_texture = nullptr;
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, texture_cache_, pixel_buffer, NULL, MTLPixelFormatRG8Unorm, pixel_width/2, pixel_height/2, 1, &cv_texture);
        texture_ = CVMetalTextureGetTexture(cv_texture);
        CFRelease(cv_texture);
        break;
      }
        
      default:
        break;
    }
    
    CVPixelBufferUnlockBaseAddress(pixel_buffer, 0);
    CVPixelBufferRelease(pixel_buffer);
  } else {
    unsigned char* pixel_data = (unsigned char *)data + offset;
    switch (format) {
      case VideoRenderTextureFormatLuminance: {
        descriptor.pixelFormat = MTLPixelFormatR8Unorm;
        texture_ = [metal_device_ newTextureWithDescriptor:descriptor];
        MTLRegion region = MTLRegionMake2D(0, 0, pixel_width, pixel_height);
        [texture_ replaceRegion:region mipmapLevel:0 withBytes:pixel_data bytesPerRow:pixel_width];
        break;
      }
      case VideoRenderTextureFormatLuminanceAlpha: {
        descriptor.width = pixel_width / 2;
        descriptor.height = pixel_height / 2;
        descriptor.pixelFormat = MTLPixelFormatRG8Unorm;
        texture_ = [metal_device_ newTextureWithDescriptor:descriptor];
        MTLRegion region = MTLRegionMake2D(0, 0, pixel_width/2, pixel_height/2);
        [texture_ replaceRegion:region mipmapLevel:0 withBytes:pixel_data bytesPerRow:pixel_width];
        break;
      }
        
      default:
        break;
    }
  }
}

id<MTLTexture> MetalTexture::GetTexture() {
  return texture_;
}
