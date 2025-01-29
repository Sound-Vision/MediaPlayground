//
//  VideoDeviceInfoCollector.m
//  MediaPlayground
//
//  Created by Viva on 2024/12/28.
//

#import "VideoDeviceInfoCollector.h"

@implementation VideoDeviceInfoCollector

+ (NSArray<AVCaptureDevice*>*)getDeviceListWithDeviceTypeList:(NSArray<AVCaptureDeviceType>*)device_type_list {
  // 选取设备
  NSArray* device_list = nil;
  
#ifdef PLATFORM_IOS
  if (@available(iOS 10.0, *)) {
//    device_type_list = @[AVCaptureDeviceTypeBuiltInWideAngleCamera];
//    device_type_list = @[AVCaptureDeviceTypeBuiltInTelephotoCamera];
//    device_type_list = @[AVCaptureDeviceTypeBuiltInUltraWideCamera];
//    device_type_list = @[AVCaptureDeviceTypeBuiltInDualCamera];
//    device_type_list = @[AVCaptureDeviceTypeBuiltInDualWideCamera];
//    device_type_list = @[AVCaptureDeviceTypeBuiltInTripleCamera];
//    device_type_list = @[AVCaptureDeviceTypeBuiltInTrueDepthCamera];
//    device_type_list = @[AVCaptureDeviceTypeBuiltInLiDARDepthCamera];
//    device_type_list = @[AVCaptureDeviceTypeContinuityCamera];
    AVCaptureDeviceDiscoverySession* device_discovery_session = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:device_type_list mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];
    device_list = device_discovery_session.devices;
  } else {
    device_list = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
  }
#endif
  
#ifdef PLATFORM_MAC
  if (@available(macOS 10.15, *)) {
    AVCaptureDeviceDiscoverySession* device_discovery_session = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:device_type_list mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];
    device_list = device_discovery_session.devices;
  } else {
    device_list = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
  }
#endif
  
  return device_list;
}

+ (NSArray<AVCaptureDeviceFormat*>*)getFormatListWithDevice:(AVCaptureDevice*)device {
  return device.formats;
}

+ (NSString*)getDescriptionForDevice:(AVCaptureDevice*)device {
  NSString* desciption = [NSString stringWithFormat:@"name:%@, position:%@, unique_id:%@, min_zoom:%@, max_zoom:%@", device.localizedName, [VideoDeviceInfoCollector getDescriptionForDevicePosition:device.position], device.uniqueID, @(device.minAvailableVideoZoomFactor), @(device.maxAvailableVideoZoomFactor)];
  return desciption;
}

+ (NSString*)getDescriptionForFormat:(AVCaptureDeviceFormat*)format {
  FourCharCode media_type = CMFormatDescriptionGetMediaType(format.formatDescription);
  FourCharCode media_sub_type = CMFormatDescriptionGetMediaSubType(format.formatDescription);
  CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
  NSString* desciption = [NSString stringWithFormat:@"%@, %@, width:%@, height:%@", [VideoDeviceInfoCollector getStringWithFourCharCode:media_type], [VideoDeviceInfoCollector getStringWithFourCharCode:media_sub_type], @(dimensions.width), @(dimensions.height)];
  return desciption;
}

+ (NSString*)getDescriptionForDevicePosition:(AVCaptureDevicePosition)position {
  switch (position) {
    case AVCaptureDevicePositionUnspecified: return @"unspecified";
    case AVCaptureDevicePositionBack: return @"back";
    case AVCaptureDevicePositionFront: return @"front";
    default:
      break;
  }
  return @"";
}

+ (NSArray<NSString *> *)getDetailListForFormat:(AVCaptureDeviceFormat *)format {
  NSArray<AVFrameRateRange*>* frame_rate_range_list = format.videoSupportedFrameRateRanges;
  NSMutableArray* detail_list = [NSMutableArray array];
  for (AVFrameRateRange* range in frame_rate_range_list) {
    NSString* detail = [NSString stringWithFormat:@"min_fps:%@, max_fps:%@", @(range.minFrameRate), @(range.maxFrameRate)];
    [detail_list addObject:detail];
  }
  return [detail_list copy];
}

+ (NSString*)getStringWithFourCharCode:(FourCharCode)fourcc {
  NSUInteger value = CFSwapInt32BigToHost(fourcc);
  NSData* data = [NSData dataWithBytes:&value length:sizeof(NSUInteger)];
  NSString* fourcc_string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  NSString* result = [fourcc_string stringByReplacingOccurrencesOfString:@"\0" withString:@""];
  return result;
}

@end
