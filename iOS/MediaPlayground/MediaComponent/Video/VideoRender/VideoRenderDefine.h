//
//  VideoRenderDefine.h
//  
//
//  Created by viva on 2021/7/17.
//

#ifndef VideoRenderDefine_h
#define VideoRenderDefine_h

#define VIDEO_RENDER_RESULT_OK 0
#define VIDEO_RENDER_RESULT_ERROR_MEMORY 1
#define VIDEO_RENDER_RESULT_ERROR_PARAMETER 2
#define VIDEO_RENDER_RESULT_ERROR_CALLORDER 3
#define VIDEO_RENDER_RESULT_ERROR_SUPPORT 4
#define VIDEO_RENDER_RESULT_ERROR_SHADER 5

#include <memory>

/// 原始数据类型
enum VideoRenderPixelDataType {
    /// 与平台相关的数据类型（例：Apple 平台中的 CVPixelBuffer）
    VideoRenderPixelDataTypePlatformRelated = 0,
    /// 通用的数据类型（内存中的数据指针）
    VideoRenderPixelDataTypeUniversal
};

/// 纹理格式
enum VideoRenderTextureFormat {
    /// RGBA
    VideoRenderTextureFormatRGBA = 0,
    /// BGRA
    VideoRenderTextureFormatBGRA,
    /// Y分量
    VideoRenderTextureFormatLuminance,
    /// UV分量
    VideoRenderTextureFormatLuminanceAlpha
};

#endif /* VideoRenderDefine_h */
