//
//  SceneVCVideoCapture.m
//  MediaPlayground
//
//  Created by Viva on 2024/12/28.
//

#import "SceneVCVideoCapture.h"
#import "VideoCapturer.h"
#import <Masonry/Masonry.h>

static NSString* const kVideoCaptureFunctionViewCellID = @"kVideoCaptureFunctionViewCellID";

typedef NS_ENUM(NSUInteger, VideoCaptureActionType) {
  VideoCaptureActionTypeSwitchToBackCamera,
  VideoCaptureActionTypeSwitchToFrontCamera,
  VideoCaptureActionTypeStartCapture,
  VideoCaptureActionTypeStopCapture
};

@interface SceneVCVideoCapture ()<VideoCapturerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UIView* previewView;
@property (nonatomic, strong) VideoCapturer* videoCapturer;

@property (nonatomic, strong) UITableView* functionListView;
@property (nonatomic, strong) NSArray<NSDictionary*>* functionInfoList;

@end

@implementation SceneVCVideoCapture

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self.view addSubview:self.previewView];
  [self.view addSubview:self.functionListView];
  
  self.videoCapturer = [[VideoCapturer alloc] init];
  [self.videoCapturer updateDelegate:self];
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
    make.width.mas_equalTo(validWidth);
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

- (void)doLogicWithActionType:(VideoCaptureActionType)actionType {
  switch (actionType) {
    case VideoCaptureActionTypeSwitchToBackCamera: {
      [self switchToBackCamera];
      break;
    }
    case VideoCaptureActionTypeSwitchToFrontCamera: {
      [self switchToFrontCamera];
      break;
    }
    case VideoCaptureActionTypeStartCapture: {
      [self startVideoCapture];
      break;
    }
    case VideoCaptureActionTypeStopCapture: {
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
  config.data_type = VideoCaptureOutputDataTypeDataBuffer;
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
  UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:kVideoCaptureFunctionViewCellID forIndexPath:indexPath];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kVideoCaptureFunctionViewCellID];
  }
  NSString* title = [self.functionInfoList[indexPath.row] objectForKey:@"title"];
  cell.textLabel.text = title;
  
  return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  NSNumber* type = [self.functionInfoList[indexPath.row] objectForKey:@"type"];
  VideoCaptureActionType actionType = (VideoCaptureActionType)[type unsignedIntegerValue];
  [self doLogicWithActionType:actionType];
}

#pragma mark - VideoCapturerDelegate

- (void)didCaptureVideoFrameWithSampleBuffer:(CMSampleBufferRef)sample_buffer width:(NSUInteger)width height:(NSUInteger)height {
//  NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)didCaptureVideoFrameWithDataBuffer:(NSData *)data_buffer width:(NSUInteger)width height:(NSUInteger)height {
//  NSLog(@"%s", __PRETTY_FUNCTION__);
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

- (UITableView *)functionListView {
  if (!_functionListView) {
    _functionListView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    [_functionListView registerClass:[UITableViewCell class] forCellReuseIdentifier:kVideoCaptureFunctionViewCellID];
    _functionListView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    _functionListView.dataSource = self;
    _functionListView.delegate = self;
  }
  return _functionListView;
}

- (NSArray<NSDictionary *> *)functionInfoList {
  if (!_functionInfoList) {
    _functionInfoList = @[
      @{@"type" : @(VideoCaptureActionTypeSwitchToBackCamera), @"title" : @"使用后置摄像头"},
      @{@"type" : @(VideoCaptureActionTypeSwitchToFrontCamera), @"title" : @"使用前置摄像头"},
      @{@"type" : @(VideoCaptureActionTypeStartCapture), @"title" : @"开始采集"},
      @{@"type" : @(VideoCaptureActionTypeStartCapture), @"title" : @"停止采集"},
    ];
  }
  return _functionInfoList;
}

@end
