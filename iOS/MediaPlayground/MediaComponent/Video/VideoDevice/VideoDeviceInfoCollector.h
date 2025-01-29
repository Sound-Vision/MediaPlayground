//
//  VideoDeviceInfoCollector.h
//  MediaPlayground
//
//  Created by Viva on 2024/12/28.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface VideoDeviceInfoCollector : NSObject

+ (NSArray<AVCaptureDevice*>*)getDeviceListWithDeviceTypeList:(NSArray<AVCaptureDeviceType>*)device_type_list;
+ (NSArray<AVCaptureDeviceFormat*>*)getFormatListWithDevice:(AVCaptureDevice*)device;
+ (NSString*)getDescriptionForDevice:(AVCaptureDevice*)device;
+ (NSString*)getDescriptionForFormat:(AVCaptureDeviceFormat*)format;
+ (NSArray<NSString*>*)getDetailListForFormat:(AVCaptureDeviceFormat*)format;
+ (NSString*)getStringWithFourCharCode:(FourCharCode)fourcc;

@end
