//
//  OpenGLESTexture.cpp
//  
//
//  Created by viva on 2021/7/17.
//

#include "OpenGLESTexture.h"

#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

OpenGLESTexture::~OpenGLESTexture() {
  texture_cache_ = nullptr;
  
  if (data_type_ == VideoRenderPixelDataTypeUniversal) {
    if (texture_id_ != 0) {
      glDeleteTextures(1, &texture_id_);
      texture_id_ = 0;
    }
  } else {
    texture_id_ = 0;
  }
}

void OpenGLESTexture::Init(VideoRenderPixelDataType data_type, CVOpenGLESTextureCacheRef texture_cache) {
  if (texture_id_ != 0) {
    return;
  }
  
  data_type_ = data_type;
  texture_cache_ = texture_cache;
  
  if (data_type == VideoRenderPixelDataTypeUniversal) {
    glActiveTexture(GL_TEXTURE0);
    
    glGenTextures(1, &texture_id_);
    glBindTexture(GL_TEXTURE_2D, texture_id_);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  }
}

void OpenGLESTexture::UpdateData(VideoRenderTextureFormat format,
                                 uint32_t pixel_width,
                                 uint32_t pixel_height,
                                 void* data,
                                 uint32_t offset) {
  if ((pixel_width == 0) || (pixel_height == 0) || (data == nullptr)) {
    return;
  }
    
  if (data_type_ == VideoRenderPixelDataTypePlatformRelated) {
    glActiveTexture(GL_TEXTURE0);
    
    CVPixelBufferRef pixel_buffer = (CVPixelBufferRef)data;
    
    CVPixelBufferRetain(pixel_buffer);
    CVPixelBufferLockBaseAddress(pixel_buffer, 0);
      
    switch (format) {
      case VideoRenderTextureFormatBGRA: {
        CVOpenGLESTextureRef cv_texture = nullptr;
        CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, texture_cache_, pixel_buffer, NULL, GL_TEXTURE_2D, GL_RGBA, pixel_width, pixel_height, GL_BGRA, GL_UNSIGNED_BYTE, 0, &cv_texture);
        texture_id_ = CVOpenGLESTextureGetName(cv_texture);
        
        glBindTexture(GL_TEXTURE_2D, texture_id_);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        CFRelease(cv_texture);
        
        break;
      }
      case VideoRenderTextureFormatLuminance: {
        CVOpenGLESTextureRef cv_texture = nullptr;
        CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, texture_cache_, pixel_buffer, NULL, GL_TEXTURE_2D, GL_LUMINANCE, pixel_width, pixel_height, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0, &cv_texture);
        texture_id_ = CVOpenGLESTextureGetName(cv_texture);
        
        glBindTexture(GL_TEXTURE_2D, texture_id_);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        CFRelease(cv_texture);
        
        break;
      }
      case VideoRenderTextureFormatLuminanceAlpha: {
        CVOpenGLESTextureRef cv_texture = nullptr;
        CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, texture_cache_, pixel_buffer, NULL, GL_TEXTURE_2D, GL_LUMINANCE_ALPHA, pixel_width / 2, pixel_height / 2, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, 1, &cv_texture);
        texture_id_ = CVOpenGLESTextureGetName(cv_texture);
        
        glBindTexture(GL_TEXTURE_2D, texture_id_);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        CFRelease(cv_texture);
        
        break;
      }
          
      default:
        break;
    }
      
    CVPixelBufferUnlockBaseAddress(pixel_buffer, 0);
    CVPixelBufferRelease(pixel_buffer);
  } else {
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture_id_);
    
    unsigned char* pixel_data = (unsigned char*)data + offset;
    switch (format) {
      case VideoRenderTextureFormatRGBA: {
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, pixel_width, pixel_height, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixel_data);
        break;
      }
      case VideoRenderTextureFormatBGRA: {
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, pixel_width, pixel_height, 0, GL_BGRA, GL_UNSIGNED_BYTE, pixel_data);
        break;
      }
      case VideoRenderTextureFormatLuminance: {
        glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, pixel_width, pixel_height, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, pixel_data);
        break;
      }
      case VideoRenderTextureFormatLuminanceAlpha: {
        glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE_ALPHA, pixel_width / 2, pixel_height / 2, 0, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, pixel_data);
        break;
      }
            
      default:
        break;
    }
  }
}

unsigned int OpenGLESTexture::GetTextureId() {
  return texture_id_;
}
