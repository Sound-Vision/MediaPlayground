//
//  SceneVCVideoRenderMetal.m
//  MediaPlayground
//
//  Created by Viva on 2025/1/11.
//

#import "SceneVCVideoRenderMetal.h"
#import "VideoCapturer.h"
#import "VideoRendererMetal.h"
#import <Masonry/Masonry.h>

static NSString* const kVideoRenderFunctionViewCellID = @"kVideoRenderFunctionViewCellID";

typedef NS_ENUM(NSUInteger, VideoRenderActionType) {
  VideoRenderActionTypeSwitchToBackCamera,
  VideoRenderActionTypeSwitchToFrontCamera,
  VideoRenderActionTypeStartCapture,
  VideoRenderActionTypeStopCapture
};

@interface SceneVCVideoRenderMetal ()<VideoCapturerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UIView* previewView;
@property (nonatomic, strong) VideoCapturer* videoCapturer;

@property (nonatomic, strong) UIView* renderView;
@property (nonatomic, strong) VideoRendererMetal* videoRenderer;

@property (nonatomic, strong) UITableView* functionListView;
@property (nonatomic, strong) NSArray<NSDictionary*>* functionInfoList;

@end

@implementation SceneVCVideoRenderMetal

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self.view addSubview:self.previewView];
  [self.view addSubview:self.renderView];
  [self.view addSubview:self.functionListView];
  
  self.videoCapturer = [[VideoCapturer alloc] init];
  [self.videoCapturer updateDelegate:self];
  
  self.videoRenderer = [[VideoRendererMetal alloc] init];
  [self.videoRenderer attachNativeView:self.renderView];
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  
  CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
  CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
  
  UIEdgeInsets safeAreaInsets = self.view.safeAreaInsets;
  CGFloat topOffset = safeAreaInsets.top;
  CGFloat bottomOffset = safeAreaInsets.bottom;
  CGFloat leftOffset = safeAreaInsets.left;
  CGFloat validWidth = screenWidth - safeAreaInsets.left - safeAreaInsets.right;
  CGFloat validHeight = screenHeight - topOffset - bottomOffset - safeAreaInsets.top - safeAreaInsets.bottom;
  
  [self.previewView mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.view).offset(topOffset);
    make.left.equalTo(self.view).offset(leftOffset);
    make.width.mas_equalTo(validWidth/2);
    make.height.mas_equalTo(validHeight/2);
  }];
  
  [self.renderView mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.previewView);
    make.left.equalTo(self.previewView.mas_right);
    make.width.mas_equalTo(validWidth/2);
    make.height.mas_equalTo(validHeight/2);
  }];
  
  [self.functionListView mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.previewView.mas_bottom);
    make.left.equalTo(self.previewView);
    make.width.mas_equalTo(validWidth);
    make.height.mas_equalTo(validHeight/2);
  }];
}

#pragma mark - Function

- (void)doLogicWithActionType:(VideoRenderActionType)actionType {
  switch (actionType) {
    case VideoRenderActionTypeSwitchToBackCamera: {
      [self switchToBackCamera];
      break;
    }
    case VideoRenderActionTypeSwitchToFrontCamera: {
      [self switchToFrontCamera];
      break;
    }
    case VideoRenderActionTypeStartCapture: {
      [self startVideoCapture];
      break;
    }
    case VideoRenderActionTypeStopCapture: {
      [self stopVideoCapture];
      break;
    }
    default:
      break;
  }
}

- (void)switchToBackCamera {
  VideoCaptureConfig* config = [[VideoCaptureConfig alloc] init];
  config.camera_type = VideoCaptureCameraTypeBack;
  config.resolution_type = VideoCaptureResolution1920x1080;
  config.frame_rate_type = VideoCaptureFrameRate60;
  config.data_type = VideoCaptureOutputDataTypeImageBuffer;
//  config.data_type = VideoCaptureOutputDataTypeDataBuffer;
  config.data_format = VideoCaptureOutputDataFormatNV12;
  config.provide_preview_layer = YES;
  
  [self.videoCapturer updateConfig:config];
}

- (void)switchToFrontCamera {
  VideoCaptureConfig* config = [[VideoCaptureConfig alloc] init];
  config.camera_type = VideoCaptureCameraTypeFront;
  config.resolution_type = VideoCaptureResolution1920x1080;
  config.frame_rate_type = VideoCaptureFrameRate60;
  config.data_type = VideoCaptureOutputDataTypeImageBuffer;
//  config.data_type = VideoCaptureOutputDataTypeDataBuffer;
  config.data_format = VideoCaptureOutputDataFormatNV12;
  config.provide_preview_layer = YES;
  
  [self.videoCapturer updateConfig:config];
}

- (void)startVideoCapture {
  [self.videoCapturer startCapture];
}

- (void)stopVideoCapture {
  [self.videoCapturer stopCapture];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.functionInfoList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:kVideoRenderFunctionViewCellID forIndexPath:indexPath];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kVideoRenderFunctionViewCellID];
  }
  NSString* title = [self.functionInfoList[indexPath.row] objectForKey:@"title"];
  cell.textLabel.text = title;
  
  return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  NSNumber* type = [self.functionInfoList[indexPath.row] objectForKey:@"type"];
  VideoRenderActionType actionType = (VideoRenderActionType)[type unsignedIntegerValue];
  [self doLogicWithActionType:actionType];
}

#pragma mark - VideoCapturerDelegate

- (void)didCaptureVideoFrameWithSampleBuffer:(CMSampleBufferRef)sample_buffer width:(NSUInteger)width height:(NSUInteger)height {
  CVPixelBufferRef pixel_buffer = CMSampleBufferGetImageBuffer(sample_buffer);
  [self.videoRenderer renderVideoFrameWithPixelBuffer:pixel_buffer width:width height:height];
}

- (void)didCaptureVideoFrameWithDataBuffer:(NSData *)data_buffer width:(NSUInteger)width height:(NSUInteger)height {
  [self.videoRenderer renderVideoFrameWithData:(void*)[data_buffer bytes] width:width height:height];
}

- (void)didFinishConfigurationWithPreviewLayer:(AVCaptureVideoPreviewLayer *)preview_layer {
  preview_layer.frame = self.previewView.bounds;
  [self.previewView.layer addSublayer:preview_layer];
}

#pragma mark - Getter

- (UIView *)previewView {
  if (!_previewView) {
    _previewView = [[UIView alloc] initWithFrame:CGRectZero];
    _previewView.backgroundColor = [UIColor redColor];
  }
  return _previewView;
}

- (UIView *)renderView {
  if (!_renderView) {
    _renderView = [[UIView alloc] initWithFrame:CGRectZero];
    _renderView.backgroundColor = [UIColor yellowColor];
  }
  return _renderView;
}

- (UITableView *)functionListView {
  if (!_functionListView) {
    _functionListView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    [_functionListView registerClass:[UITableViewCell class] forCellReuseIdentifier:kVideoRenderFunctionViewCellID];
    _functionListView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    _functionListView.dataSource = self;
    _functionListView.delegate = self;
  }
  return _functionListView;
}

- (NSArray<NSDictionary *> *)functionInfoList {
  if (!_functionInfoList) {
    _functionInfoList = @[
      @{@"type" : @(VideoRenderActionTypeSwitchToBackCamera), @"title" : @"使用后置摄像头"},
      @{@"type" : @(VideoRenderActionTypeSwitchToFrontCamera), @"title" : @"使用前置摄像头"},
      @{@"type" : @(VideoRenderActionTypeStartCapture), @"title" : @"开始采集"},
      @{@"type" : @(VideoRenderActionTypeStopCapture), @"title" : @"停止采集"},
    ];
  }
  return _functionInfoList;
}

@end
