//
//  VideoCapturer.m
//  MediaPlayground
//
//  Created by Viva on 2024/12/28.
//

#import "VideoCapturer.h"
#import "VideoCaptureDefine.h"
#import "VideoDeviceInfoCollector.h"

@interface VideoCapturer ()<AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate>

/// 视频采集会话（管理 input 和 output 对象，控制整个视频采集流程）
@property (nonatomic, strong) AVCaptureSession* capture_session;
/// 视频采集设备（摄像头）
@property (nonatomic, strong) AVCaptureDevice* device;
/// 视频输入对象
@property (nonatomic, strong) AVCaptureDeviceInput* device_input;
/// 视频数据输出对象
@property (nonatomic, strong) AVCaptureVideoDataOutput* data_output;
//@property (nonatomic, strong) AVCapturePhotoOutput* photo_output;
/// connection 对象，控制输出数据的参数
@property (nonatomic, strong) AVCaptureConnection* data_output_connection;
/// 图像预览层（显示实时采集的画面）
@property (nonatomic, strong) AVCaptureVideoPreviewLayer* preview_layer;
/// 已选择的格式
@property (nonatomic, strong) NSNumber* selected_pixel_format;

@property (nonatomic, strong) VideoCaptureConfig* capture_config;
@property (nonatomic, weak) id<VideoCapturerDelegate> delegate;

@end

@implementation VideoCapturer {
  /// 视频输出队列（必须串行）
  dispatch_queue_t data_output_queue_;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    data_output_queue_ = dispatch_queue_create("com.viva.video.capture.data.output.queue", DISPATCH_QUEUE_SERIAL);
    _capture_session = [[AVCaptureSession alloc] init];
  }
  return self;
}

#pragma mark - public

- (void)updateConfig:(VideoCaptureConfig*)config {
  _capture_config = config;
  
  [self.capture_session stopRunning];
  
  NSError* error = nil;
  
  // device
  [self configureVideoCaptureDeviceWithError:&error];
  if (error) {
    NSLog(@"[VideoCapturer] - configure video capture device failed, error:%@", error);
    return;
  }
  
  [self.device lockForConfiguration:NULL];
  [self.capture_session beginConfiguration];
  
  // input
  [self configureVideoInputWithError:&error];
  if (error) {
    NSLog(@"[VideoCapturer] - configure video input failed, error:%@", error);
    [self.capture_session commitConfiguration];
    [self.device unlockForConfiguration];
    return;
  }
  
  // output
  [self configureVideoOutputWithError:&error];
  if (error) {
    NSLog(@"[VideoCapturer] - configure video output failed, error:%@", error);
    [self.capture_session commitConfiguration];
    [self.device unlockForConfiguration];
    return;
  }
  
  [self.capture_session commitConfiguration];
  
  if (self.capture_config.provide_preview_layer && [self.delegate respondsToSelector:@selector(didFinishConfigurationWithPreviewLayer:)]) {
    self.preview_layer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.capture_session];
    self.preview_layer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.delegate didFinishConfigurationWithPreviewLayer:self.preview_layer];
  }
  
#ifdef PLATFORM_MAC
  // macOS 的 capture_session 必须先启动，再设置自定义的分辨率和帧率
  // 否则后面涉及启动操作时，其内部会自动覆盖自定义的视频分辨率和帧率配置
  // 在 capture_session 改变 configuration 之前，执行 stopRunning 或 startRunning 都不会影响自定义配置
  [self.capture_session startRunning];
#endif
  
  // resolution & frame_rate
  [self configureVideoResolutionAndFrameRate];
  
  [self.device unlockForConfiguration];
}

- (void)startCapture {
  [self.capture_session startRunning];
}

- (void)stopCapture {
  [self.capture_session stopRunning];
}

- (void)updateDelegate:(id<VideoCapturerDelegate>)delegate {
  self.delegate = delegate;
}

#pragma mark - private

- (void)configureVideoCaptureDeviceWithError:(NSError**)error {
#ifdef PLATFORM_IOS
  NSArray* device_type_list = @[AVCaptureDeviceTypeBuiltInWideAngleCamera];
  NSArray<AVCaptureDevice*>* device_list = [VideoDeviceInfoCollector getDeviceListWithDeviceTypeList:device_type_list];
  AVCaptureDevicePosition position = [self queryDevicePositionWithCameraType:self.capture_config.camera_type];
  for (AVCaptureDevice* device in device_list) {
    if (device.position == position) {
      self.device = device;
      break;
    }
  }
#endif
  
#ifdef PLATFORM_MAC
  NSArray<AVCaptureDevice*>* device_list = [VideoDeviceInfoCollector getDeviceListWithDeviceTypeList:@[AVCaptureDeviceTypeBuiltInWideAngleCamera, AVCaptureDeviceTypeExternalUnknown]];
  if (device_list.count > 0) {
    if (self.capture_config.capture_device && [deviceArray containsObject:self.capture_config.capture_device]) {
      // 系统内部有缓存，可以直接用 containsObject 进行判断
      self.device = self.capture_config.capture_device;
    } else {
      self.device = device_list.firstObject;
    }
  }
#endif
  
  if (!self.device) {
    *error = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:@{@"error_message_key" : @"[VideoCapture] - device not found"}];
  }
}

- (void)configureVideoInputWithError:(NSError**)error {
  // 初始化输入对象
  AVCaptureDeviceInput* new_device_input = [[AVCaptureDeviceInput alloc] initWithDevice:self.device error:error];
  if (*error) {
    return;
  }
  
  if ([self.capture_session.inputs containsObject:self.device_input]) {
    [self.capture_session removeInput:self.device_input];
  }
  
  self.device_input = new_device_input;
  if ([self.capture_session canAddInput:self.device_input]) {
    [self.capture_session addInput:self.device_input];
  } else {
    *error = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:@{@"error_message_key" : @"[VideoCapture] - capture_session can not add device_input"}];
  }
}

- (void)configureVideoOutputWithError:(NSError**)error {
  if ([self.capture_session.outputs containsObject:self.data_output]) {
    [self.capture_session removeOutput:self.data_output];
  }
  
//  self.photo_output = [[AVCapturePhotoOutput alloc] init];
//  if ([self.capture_session canAddOutput:self.photo_output]) {
//    [self.capture_session addOutput:self.photo_output];
//  }
//  BOOL is_pro_raw_supported = self.photo_output.isAppleProRAWSupported;
//  NSLog(@"[VideoCapture] - photo output isAppleProRAWSupported:%@", @(is_pro_raw_supported));
////  self.photo_output.appleProRAWEnabled = YES;
//  NSArray<NSNumber*>* photo_formats = self.photo_output.availablePhotoPixelFormatTypes;
//  for (NSNumber* format_number in photo_formats) {
//    NSString* format_string = [VideoDeviceInfoCollector getStringWithFourCharCode:[format_number unsignedIntegerValue]];
//    NSLog(@"[VideoCapture] - supported photo pixel format = %@", format_string);
//  }
//  NSArray<NSNumber*>* raw_photo_formats = self.photo_output.availableRawPhotoPixelFormatTypes;
//  for (NSNumber* format_number in raw_photo_formats) {
//    NSString* format_string = [VideoDeviceInfoCollector getStringWithFourCharCode:[format_number unsignedIntegerValue]];
//    NSLog(@"[VideoCapture] - supported raw photo pixel format = %@", format_string);
//  }
//  return;
  
  self.data_output = [[AVCaptureVideoDataOutput alloc] init];
  
  // 设置格式
  NSNumber* format_obj = nil;
  switch (self.capture_config.data_format) {
    case VideoCaptureOutputDataFormatNV12: {
      format_obj = @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange);
      break;
    }
    case VideoCaptureOutputDataFormatBGRA: {
      format_obj = @(kCVPixelFormatType_32BGRA);
      break;
    }
    default:
      break;
  }
  
  NSArray<NSNumber*>* supported_formats = self.data_output.availableVideoCVPixelFormatTypes;
  for (NSNumber* format_number in supported_formats) {
    NSString* format_string = [VideoDeviceInfoCollector getStringWithFourCharCode:[format_number unsignedIntegerValue]];
    NSLog(@"[VideoCapture] - supported output format = %@", format_string);
  }
  if (!format_obj) {
    *error = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:@{@"error_message_key" : @"[VideoCapture] - output format is invalid, please check your capture config"}];
    return;
  }
  if (![supported_formats containsObject:format_obj]) {
    if (self.capture_config.data_format == VideoCaptureOutputDataFormatNV12) {
      // rollback, full range => video range
      BOOL is_video_range_supported = [supported_formats containsObject:@(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)];
      if (!is_video_range_supported) {
        *error = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:@{@"error_message_key" : @"[VideoCapture] - output format is not supported, better change your device"}];
        return;
      } else {
        format_obj = @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange);
      }
    } else {
      // no rollback
      *error = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:@{@"error_message_key" : @"[VideoCapture] - output format is not supported"}];
      return;
    }
  }
  
  NSDictionary* settings = [NSDictionary dictionaryWithObjectsAndKeys:format_obj, kCVPixelBufferPixelFormatTypeKey, nil];
  self.selected_pixel_format = format_obj;
  [self.data_output setVideoSettings:settings];
  
  // 数据回调放在串行队列中
  [self.data_output setSampleBufferDelegate:self queue:data_output_queue_];
  
  // 设置采集过程中的丢帧逻辑
  [self.data_output setAlwaysDiscardsLateVideoFrames:NO];
  
  // 将 output 对象添加到 capture_session
  if ([self.capture_session canAddOutput:self.data_output]) {
    [self.capture_session addOutput:self.data_output];
  } else {
    *error = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:@{@"error_message_key" : @"[VideoCapture] - capture_session can not add data_output"}];
    return;
  }
  
#ifdef PLATFORM_IOS
  // 获取 connection 对象，配置视频输出的参数
  // connection 对象必须在 output 对象已经添加到 session 之后才能获取到
  self.data_output_connection = [self.data_output connectionWithMediaType:AVMediaTypeVideo];
  if (self.data_output_connection.isVideoOrientationSupported) {
    // 默认情况下videoOrientation为AVCaptureVideoOrientationLandscapeLeft
    self.data_output_connection.videoOrientation = [self queryVideoOrientationWithType:self.capture_config.orientation];
  }
  
  if (self.data_output_connection.isVideoMirroringSupported && (self.capture_config.camera_type == VideoCaptureCameraTypeFront)) {
    // iOS 和 macOS 平台，isVideoMirroringSupported 都会返回 YES
    // 但是设置 videoMirrored 之后，只有 iOS 上使用前置摄像头时才会生效
    self.data_output_connection.videoMirrored = self.capture_config.enable_mirror_for_front_camera;
  }
#endif
}

- (void)configureVideoResolutionAndFrameRate {
  NSUInteger frame_rate = [self queryFrameRateWithType:self.capture_config.frame_rate_type];
//  NSArray<NSNumber*>* available_pixel_format_list = self.dataOutput.availableVideoCVPixelFormatTypes;
  for (AVCaptureDeviceFormat* format in self.device.formats) {
    FourCharCode media_sub_type = CMFormatDescriptionGetMediaSubType(format.formatDescription);
//    if (![available_pixel_format_list containsObject:@(media_sub_type)]) {
//      continue;
//    }
    if (!([self.selected_pixel_format unsignedIntValue] == media_sub_type)) {
      continue;
    }
    
    NSArray<AVFrameRateRange*>* range_list = format.videoSupportedFrameRateRanges;
    for (AVFrameRateRange* range in range_list) {
      if (frame_rate == (NSUInteger)range.maxFrameRate) {
        CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
        if (dimensions.width == [self.capture_config getResolutionWidth] &&
            dimensions.height == [self.capture_config getResolutionHeight]) {
          [self.device setActiveFormat:format];
          [self.device setActiveVideoMinFrameDuration:range.minFrameDuration];
          [self.device setActiveVideoMaxFrameDuration:range.minFrameDuration];
          return;
        }
      }
    }
  }
  
  NSLog(@"[VideoCapture] - frameRate %ld not compatible with current configuration(width = %lu, height = %lu) when using current device, using default configuration instead", frame_rate, [self.capture_config getResolutionWidth], [self.capture_config getResolutionHeight]);
  
  AVCaptureSessionPreset preset = [self querySessionPresetWithResolution:self.capture_config.resolution_type];
  [self.capture_session setSessionPreset:preset];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
  CVPixelBufferRef pixel_buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
  size_t width = CVPixelBufferGetWidth(pixel_buffer);
  size_t height = CVPixelBufferGetHeight(pixel_buffer);
  switch (self.capture_config.data_type) {
    case VideoCaptureOutputDataTypeImageBuffer: {
      if (self.delegate && [self.delegate respondsToSelector:@selector(didCaptureVideoFrameWithSampleBuffer:width:height:)]) {
        [self.delegate didCaptureVideoFrameWithSampleBuffer:sampleBuffer width:width height:height];
      }
      break;
    }
    case VideoCaptureOutputDataTypeDataBuffer: {
      if (self.delegate && [self.delegate respondsToSelector:@selector(didCaptureVideoFrameWithDataBuffer:width:height:)]) {
        NSData* data_buffer = [self extractDataFromPixelBuffer:pixel_buffer];
        [self.delegate didCaptureVideoFrameWithDataBuffer:data_buffer width:width height:height];
      }
      break;
    }
    default:
      break;
  }
}

- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
}

#pragma mark - util

#ifdef PLATFORM_IOS
- (AVCaptureDevicePosition)queryDevicePositionWithCameraType:(VideoCaptureCameraType)type {
  AVCaptureDevicePosition position = AVCaptureDevicePositionUnspecified;
  
  switch (type) {
    case VideoCaptureCameraTypeBack: {
      position = AVCaptureDevicePositionBack;
      break;
    }
    case VideoCaptureCameraTypeFront: {
      position = AVCaptureDevicePositionFront;
      break;
    }
    default:
      break;
  }
  
  return position;
}

- (AVCaptureVideoOrientation)queryVideoOrientationWithType:(VideoCaptureOrientation)type {
  AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationPortrait;
  
  switch (type) {
    case VideoCaptureOrientationPortrait: {
      orientation = AVCaptureVideoOrientationPortrait;
      break;
    }
    case VideoCaptureOrientationPortraitUpsideDown: {
      orientation = AVCaptureVideoOrientationPortraitUpsideDown;
      break;
    }
    case VideoCaptureOrientationLandscapeRight: {
      orientation = AVCaptureVideoOrientationLandscapeRight;
      break;
    }
    case VideoCaptureOrientationLandscapeLeft: {
      orientation = AVCaptureVideoOrientationLandscapeLeft;
      break;
    }
    default:
      break;
  }
  
  return orientation;
}
#endif

- (AVCaptureSessionPreset)querySessionPresetWithResolution:(VideoCaptureResolution)resolution {
  AVCaptureSessionPreset preset = AVCaptureSessionPresetHigh;
  
  switch (resolution) {
    case VideoCaptureResolution3840x2160: {
      if (@available(macOS 10.15, *)) {
        preset = AVCaptureSessionPreset3840x2160;
      } else {
        preset = AVCaptureSessionPreset1280x720;
      }
      break;
    }
    case VideoCaptureResolution1920x1080: {
      if (@available(macOS 10.15, *)) {
        preset = AVCaptureSessionPreset1920x1080;
      } else {
        preset = AVCaptureSessionPreset1280x720;
      }
      break;
    }
    case VideoCaptureResolution1280x720: {
      preset = AVCaptureSessionPreset1280x720;
      break;
    }
    case VideoCaptureResolution640x480: {
      preset = AVCaptureSessionPreset640x480;
      break;
    }
    case VideoCaptureResolution352x288: {
      preset = AVCaptureSessionPreset352x288;
      break;
    }
    default:
      break;
  }
  
  do {
    if ([self.capture_session canSetSessionPreset:preset]) {
      break;
    }
    if ([self.capture_session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
      preset = AVCaptureSessionPresetHigh;
      break;
    }
    if ([self.capture_session canSetSessionPreset:AVCaptureSessionPresetMedium]) {
      preset = AVCaptureSessionPresetMedium;
      break;
    }
    preset = AVCaptureSessionPresetLow;
  } while (0);
  
  return preset;
}

- (NSUInteger)queryFrameRateWithType:(VideoCaptureFrameRate)type {
  NSUInteger frame_rate = 30;
  
  switch (type) {
    case VideoCaptureFrameRate60: {
      frame_rate = 60;
      break;
    }
    case VideoCaptureFrameRate30: {
      frame_rate = 30;
      break;
    }
    case VideoCaptureFrameRate25: {
      frame_rate = 25;
      break;
    }
    case VideoCaptureFrameRate20: {
      frame_rate = 20;
      break;
    }
    case VideoCaptureFrameRate15: {
      frame_rate = 15;
      break;
    }
    case VideoCaptureFrameRate10: {
      frame_rate = 10;
      break;
    }
    case VideoCaptureFrameRate5: {
      frame_rate = 5;
      break;
    }
    default:
      break;
  }
  
  return frame_rate;
}

- (NSData*)extractDataFromPixelBuffer:(CVPixelBufferRef)pixel_buffer {
  CVPixelBufferLockBaseAddress(pixel_buffer, 0);
  
  size_t pixel_width = CVPixelBufferGetWidth(pixel_buffer);
  size_t pixel_height = CVPixelBufferGetHeight(pixel_buffer);
  
  unsigned long data_length = 0;
  unsigned char* output_data = NULL;
  if (self.capture_config.data_format == VideoCaptureOutputDataFormatNV12) {
    // 提取 NV12 数据
    data_length = pixel_width * pixel_height / 2 * 3;
    output_data = (unsigned char*)malloc(data_length);
    memset(output_data, 0, data_length);
    
    unsigned char* y_data = (unsigned char*)CVPixelBufferGetBaseAddressOfPlane(pixel_buffer, 0);
    unsigned char* uv_data = (unsigned char*)CVPixelBufferGetBaseAddressOfPlane(pixel_buffer, 1);
    size_t y_data_size_per_row = CVPixelBufferGetBytesPerRowOfPlane(pixel_buffer, 0);
    size_t uv_data_size_per_row = CVPixelBufferGetBytesPerRowOfPlane(pixel_buffer, 1);
    size_t y_data_size = pixel_width * pixel_height;
    if (pixel_width != y_data_size_per_row) {
      // 考虑到 pixel_buffer 中内存对齐
      // 当每行数据长度与视频宽不一致时，逐行进行数据拷贝
      for (int i = 0; i < pixel_height; i++) {
        memcpy(output_data + pixel_width * i, y_data + y_data_size_per_row * i, pixel_width);
      }
      for (int i = 0; i < (pixel_height >> 1); i++) {
        memcpy(output_data + y_data_size + pixel_width * i, uv_data + uv_data_size_per_row * i, pixel_width);
      }
    } else {
      // 直接拷贝
      memcpy(output_data, y_data, y_data_size);
      memcpy(output_data + y_data_size, uv_data, y_data_size >> 1);
    }
  } else if (self.capture_config.data_format == VideoCaptureOutputDataFormatBGRA) {
    // 提取数据
    data_length = pixel_width * pixel_height * 4;
    output_data = (unsigned char*)malloc(data_length);
    memset(output_data, 0, data_length);
    
    unsigned char* data_buffer = CVPixelBufferGetBaseAddress(pixel_buffer);
    size_t data_size_per_row = CVPixelBufferGetBytesPerRow(pixel_buffer);
    if ((pixel_width * 4) != data_size_per_row) {
      // 考虑到 pixel_buffer 中内存对齐，逐行进行数据拷贝
      for (int i = 0; i < pixel_height; i++) {
        for (int j = 0; j < 4; j++) {
          memcpy(output_data + pixel_width * 4 * i + pixel_width * j, data_buffer + data_size_per_row * i + data_size_per_row / 4 * j, pixel_width);
        }
      }
    } else {
      // 直接拷贝
      memcpy(output_data, data_buffer, data_length);
    }
  }
  
  CVPixelBufferUnlockBaseAddress(pixel_buffer, 0);
  
  return [[NSData alloc] initWithBytesNoCopy:output_data length:data_length freeWhenDone:YES];
}

@end
