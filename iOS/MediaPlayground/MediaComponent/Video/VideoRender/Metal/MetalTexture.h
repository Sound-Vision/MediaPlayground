//
//  MetalTexture.hpp
//  
//
//  Created by Viva on 2023/8/12.
//

#ifndef MetalTexture_hpp
#define MetalTexture_hpp

#include "VideoRenderDefine.h"
#include <CoreVideo/CoreVideo.h>

class MetalTexture {
  
public:
  MetalTexture();
  
  ~MetalTexture();
  
  void Init(VideoRenderPixelDataType data_type, CVMetalTextureCacheRef texture_cache, id<MTLDevice> metal_device);
  
  void UpdateData(VideoRenderTextureFormat format,
                  uint32_t pixel_width,
                  uint32_t pixel_height,
                  void* data,
                  uint32_t offset);
  
  id<MTLTexture> GetTexture();
  
private:
  VideoRenderPixelDataType data_type_ = VideoRenderPixelDataTypePlatformRelated;
  
  CVMetalTextureCacheRef texture_cache_ = NULL;
  
  id<MTLDevice> metal_device_ = nil;
  
  id<MTLTexture> texture_ = nil;
};

#endif /* MetalTexture_hpp */
