//
//  VideoCaptureDefine.h
//  MediaCapture
//
//  Created by viva on 2019/8/6.
//  Copyright © 2019 viva. All rights reserved.
//

#ifndef VideoCaptureDefine_h
#define VideoCaptureDefine_h

#import <AVFoundation/AVFoundation.h>

#ifdef PLATFORM_IOS
typedef NS_ENUM(NSInteger, VideoCaptureCameraType) {
  /// 前置摄像头
  VideoCaptureCameraTypeFront,
  /// 后置摄像头
  VideoCaptureCameraTypeBack
};
#endif

typedef NS_ENUM(NSInteger, VideoCaptureResolution) {
  /// 4K
  VideoCaptureResolution3840x2160,
  /// 1080p
  VideoCaptureResolution1920x1080,
  /// 720p
  VideoCaptureResolution1280x720,
  /// 480p
  VideoCaptureResolution640x480,
  /// CIF
  VideoCaptureResolution352x288
};

typedef NS_ENUM(NSInteger, VideoCaptureFrameRate) {
  /// 帧率 60
  VideoCaptureFrameRate60,
  /// 帧率 30
  VideoCaptureFrameRate30,
  /// 帧率 25
  VideoCaptureFrameRate25,
  /// 帧率 20
  VideoCaptureFrameRate20,
  /// 帧率 15
  VideoCaptureFrameRate15,
  /// 帧率 10
  VideoCaptureFrameRate10,
  /// 帧率 5
  VideoCaptureFrameRate5
};

typedef NS_ENUM(NSInteger, VideoCaptureOrientation) {
  VideoCaptureOrientationPortrait,
  VideoCaptureOrientationPortraitUpsideDown,
  VideoCaptureOrientationLandscapeRight,
  VideoCaptureOrientationLandscapeLeft
};

typedef NS_ENUM(NSInteger, VideoCaptureOutputDataType) {
  /// CVPixelBuffer
  VideoCaptureOutputDataTypeImageBuffer,
  /// 拷贝到内存中的数据
  VideoCaptureOutputDataTypeDataBuffer
};

typedef NS_ENUM(NSInteger, VideoCaptureOutputDataFormat) {
  /// NV12
  VideoCaptureOutputDataFormatNV12,
  /// BGRA
  VideoCaptureOutputDataFormatBGRA
};

@interface VideoCaptureConfig : NSObject

#ifdef PLATFORM_IOS
/// 摄像头类型（默认：VideoCaptureCameraTypeBack）
@property (nonatomic, assign) VideoCaptureCameraType camera_type;

/// 图像方向（默认：VideoCaptureOrientationPortrait）
@property (nonatomic, assign) VideoCaptureOrientation orientation;

/// 是否反转前置摄像头的图像（默认：NO）
@property (nonatomic, assign) BOOL enable_mirror_for_front_camera;
#endif

#ifdef PLATFORM_MAC
/// 采集设备（默认：nil）
@property (nonatomic, weak, nullable) AVCaptureDevice *capture_device;
#endif

/// 分辨率类型（默认：VideoCaptureResolution1280x720）
@property (nonatomic, assign) VideoCaptureResolution resolution_type;

/// 帧率类型（默认：VideoCaptureFrameRate30）
@property (nonatomic, assign) VideoCaptureFrameRate frame_rate_type;

/// 数据类型（默认：VideoCaptureOutputDataTypeImageBuffer）
@property (nonatomic, assign) VideoCaptureOutputDataType data_type;

/// 数据格式（默认：VideoCaptureOutputDataFormatNV12）
@property (nonatomic, assign) VideoCaptureOutputDataFormat data_format;

/// 是否提供预览图层（默认：NO）
@property (nonatomic, assign) BOOL provide_preview_layer;

/// 获取分辨率宽度
- (NSUInteger)getResolutionWidth;

/// 获取分辨率高度
- (NSUInteger)getResolutionHeight;

@end

#endif /* VideoCaptureDefine_h */
