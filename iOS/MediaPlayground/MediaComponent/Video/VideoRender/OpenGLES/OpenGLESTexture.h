//
//  OpenGLESTexture.hpp
//  
//
//  Created by viva on 2021/7/17.
//

#ifndef OpenGLESTexture_hpp
#define OpenGLESTexture_hpp

#include "VideoRenderDefine.h"

#include <CoreVideo/CoreVideo.h>

class OpenGLESTexture {
public:
  ~OpenGLESTexture();
public:
  void Init(VideoRenderPixelDataType data_type, CVOpenGLESTextureCacheRef texture_cache = NULL);
  void UpdateData(VideoRenderTextureFormat format,
                  uint32_t pixel_width,
                  uint32_t pixel_height,
                  void* data,
                  uint32_t offset);
  unsigned int GetTextureId();
private:
  VideoRenderPixelDataType data_type_ = VideoRenderPixelDataTypeUniversal;
  CVOpenGLESTextureCacheRef texture_cache_ = NULL;
  unsigned int texture_id_;
};

#endif /* OpenGLESTexture_hpp */
