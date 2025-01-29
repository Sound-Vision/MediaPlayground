//
//  VideoCaptureDefine.m
//  MediaPlayground
//
//  Created by Viva on 2024/12/28.
//

#import "VideoCaptureDefine.h"

@interface VideoCaptureConfig ()

@property (nonatomic, assign) NSUInteger resolution_width;
@property (nonatomic, assign) NSUInteger resolution_height;

@end

@implementation VideoCaptureConfig

- (instancetype)init {
  self = [super init];
  if (self) {
#ifdef PLATFORM_IOS
    self.camera_type = VideoCaptureCameraTypeBack;
    self.orientation = VideoCaptureOrientationPortrait;
    self.enable_mirror_for_front_camera = NO;
#endif
#ifdef PLATFORM_MAC
    self.captureDevice = nil;
#endif
    self.resolution_type = VideoCaptureResolution1280x720;
    self.frame_rate_type = VideoCaptureFrameRate30;
    self.data_type = VideoCaptureOutputDataTypeImageBuffer;
    self.data_format = VideoCaptureOutputDataFormatNV12;
    
    self.resolution_width = 1280;
    self.resolution_height = 720;
  }
  return self;
}

- (NSUInteger)getResolutionWidth {
  switch (self.resolution_type) {
    case VideoCaptureResolution3840x2160: { return 3840; }
    case VideoCaptureResolution1920x1080: { return 1920;}
    case VideoCaptureResolution1280x720: { return 1280;}
    case VideoCaptureResolution640x480: { return 640;}
    case VideoCaptureResolution352x288: { return 352;}
    default:
      break;
  }
  return 0;
}

- (NSUInteger)getResolutionHeight {
  switch (self.resolution_type) {
    case VideoCaptureResolution3840x2160: { return 2160; }
    case VideoCaptureResolution1920x1080: { return 1080;}
    case VideoCaptureResolution1280x720: { return 720;}
    case VideoCaptureResolution640x480: { return 480;}
    case VideoCaptureResolution352x288: { return 288;}
    default:
      break;
  }
  return 0;
}

@end
