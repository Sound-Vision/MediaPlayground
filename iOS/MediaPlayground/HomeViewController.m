//
//  HomeViewController.m
//  MediaPlayground
//
//  Created by Viva on 2024/11/16.
//

#import "HomeViewController.h"
#import "MediaScene/BaseSceneVC.h"
#import "MediaComponent/CLSystemAuthorityManager.h"

static NSString* kMediaSceneViewCellID = @"kMediaSceneViewCellID";

typedef NS_ENUM(NSUInteger, MediaCategoryType) {
  MediaCategoryTypeVideo = 0,
  MediaCategoryTypeAudio,
  MediaCategoryTypeVideoAndAudio
};

typedef NS_ENUM(NSUInteger, MediaSceneType) {
  MediaSceneTypeVideoDeviceManagment = 0,
  MediaSceneTypeVideoCapture,
  MediaSceneTypeVideoRenderOpenGLES,
  MediaSceneTypeVideoRenderMetal,
  MediaSceneTypeVideoEncodeHardware,
  MediaSceneTypeVideoDecodeHardware,
  MediaSceneTypeAudioSessionManagment,
  MediaSceneTypeAudioDeviceManagment,
  MediaSceneTypeAudioCapture,
  MediaSceneTypeAudioRender
};

@interface HomeViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView* mediaSceneView;
@property (nonatomic, strong) NSArray<NSNumber*>* mediaCategoryArray;
@property (nonatomic, strong) NSDictionary<NSNumber*, NSString*>* mediaCategoryTitleMap;
@property (nonatomic, strong) NSDictionary<NSNumber*, NSArray<NSNumber*>*>* mediaSceneMap;
@property (nonatomic, strong) NSDictionary<NSNumber*, NSString*>* mediaSceneTitleMap;
@property (nonatomic, strong) NSDictionary<NSNumber*, NSString*>* mediaSceneDetailMap;
@property (nonatomic, strong) NSDictionary<NSNumber*, NSString*>* mediaSceneClassNameMap;

@end

@implementation HomeViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.title = @"Media Playground";
  self.view.backgroundColor = [UIColor whiteColor];
  [self.view addSubview:self.mediaSceneView];
  [self.mediaSceneView reloadData];
  
  [self requestPermissions];
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  
  UIEdgeInsets safeAreaInsets = self.view.safeAreaInsets;
  CGFloat x = safeAreaInsets.left;
  CGFloat y = safeAreaInsets.top;
  CGFloat width = self.view.bounds.size.width - safeAreaInsets.left - safeAreaInsets.right;
  CGFloat height = self.view.bounds.size.height - safeAreaInsets.top - safeAreaInsets.bottom;
  self.mediaSceneView.frame = CGRectMake(x, y, width, height);
}

- (void)requestPermissions {
  [CLSystemAuthorityManager checkCameraAuthorizationWithAuthorizedHandler:^{
    NSLog(@"摄像头已授权");
  } restrictedHandler:^{
    NSLog(@"摄像头未授权");
  } deniedHandler:^{
    NSLog(@"摄像头未授权");
  }];
  
  [CLSystemAuthorityManager checkMicrophoneAuthorizationWithAuthorizedHandler:^{
    NSLog(@"麦克风已授权");
  } restrictedHandler:^{
    NSLog(@"麦克风未授权");
  } deniedHandler:^{
    NSLog(@"麦克风未授权");
  }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return self.mediaCategoryArray.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  return [self.mediaCategoryTitleMap objectForKey:@(section)];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  MediaCategoryType category = [[self.mediaCategoryArray objectAtIndex:section] unsignedIntegerValue];
  return [self.mediaSceneMap objectForKey:@(category)].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:kMediaSceneViewCellID];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kMediaSceneViewCellID];
  }
  
  MediaCategoryType category = [[self.mediaCategoryArray objectAtIndex:indexPath.section] unsignedIntegerValue];
  NSArray* sceneArray = [self.mediaSceneMap objectForKey:@(category)];
  MediaSceneType scene = [[sceneArray objectAtIndex:indexPath.row] unsignedIntegerValue];
  
  cell.textLabel.text = [self.mediaSceneTitleMap objectForKey:@(scene)];
  cell.detailTextLabel.text = [self.mediaSceneDetailMap objectForKey:@(scene)];
  
  return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  MediaCategoryType category = [[self.mediaCategoryArray objectAtIndex:indexPath.section] unsignedIntegerValue];
  NSArray* sceneArray = [self.mediaSceneMap objectForKey:@(category)];
  MediaSceneType scene = [[sceneArray objectAtIndex:indexPath.row] unsignedIntegerValue];
  
  NSString* categoryTitle = [self.mediaCategoryTitleMap objectForKey:@(category)];
  NSString* sceneTitle = [self.mediaSceneTitleMap objectForKey:@(scene)];
  NSString* vcTitle = [NSString stringWithFormat:@"%@-%@", categoryTitle, sceneTitle];
  
  NSString* vcClassName = [self.mediaSceneClassNameMap objectForKey:@(scene)];
  Class vcClass = NSClassFromString(vcClassName);
  BaseSceneVC* vc = [[vcClass alloc] init];
  [vc updateTitle:vcTitle];
  [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Getter

- (UITableView *)mediaSceneView {
  if (!_mediaSceneView) {
    _mediaSceneView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _mediaSceneView.dataSource = self;
    _mediaSceneView.delegate = self;
    _mediaSceneView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
  }
  return _mediaSceneView;
}

- (NSArray<NSNumber *> *)mediaCategoryArray {
  if (!_mediaCategoryArray) {
    _mediaCategoryArray = @[
      @(MediaCategoryTypeVideo),
      @(MediaCategoryTypeAudio),
//      @(MediaCategoryTypeVideoAndAudio)
    ];
  }
  return _mediaCategoryArray;
}

- (NSDictionary<NSNumber *,NSString *> *)mediaCategoryTitleMap {
  if (!_mediaCategoryTitleMap) {
    _mediaCategoryTitleMap = @{
      @(MediaCategoryTypeVideo) : @"视频",
      @(MediaCategoryTypeAudio) : @"音频",
      @(MediaCategoryTypeVideoAndAudio) : @"视频+音频"
    };
  }
  return _mediaCategoryTitleMap;
}

- (NSDictionary<NSNumber *,NSArray<NSNumber *> *> *)mediaSceneMap {
  if (!_mediaSceneMap) {
    NSArray* videoSceneArray = @[
      @(MediaSceneTypeVideoDeviceManagment),
      @(MediaSceneTypeVideoCapture),
      @(MediaSceneTypeVideoRenderOpenGLES),
    ];
    
    NSArray* audioSceneArray = @[
      @(MediaSceneTypeAudioSessionManagment),
      @(MediaSceneTypeAudioDeviceManagment),
      @(MediaSceneTypeAudioCapture),
      @(MediaSceneTypeAudioRender),
    ];
    
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    [dict setObject:videoSceneArray forKey:@(MediaCategoryTypeVideo)];
    [dict setObject:audioSceneArray forKey:@(MediaCategoryTypeAudio)];
    _mediaSceneMap = [dict copy];
  }
  return _mediaSceneMap;
}

- (NSDictionary<NSNumber *,NSString *> *)mediaSceneTitleMap {
  if (!_mediaSceneTitleMap) {
    _mediaSceneTitleMap = @{
      @(MediaSceneTypeVideoDeviceManagment) : @"设备管理",
      @(MediaSceneTypeVideoCapture) : @"采集",
      @(MediaSceneTypeVideoRenderOpenGLES) : @"渲染（OpenGLES）",
      @(MediaSceneTypeVideoRenderMetal) : @"渲染（Metal）",
      @(MediaSceneTypeVideoEncodeHardware) : @"编码（硬件）",
      @(MediaSceneTypeVideoDecodeHardware) : @"解码（软件）",
      @(MediaSceneTypeAudioSessionManagment) : @"AudioSession",
      @(MediaSceneTypeAudioDeviceManagment) : @"设备管理",
      @(MediaSceneTypeAudioCapture) : @"采集",
      @(MediaSceneTypeAudioRender) : @"渲染",
    };
  }
  return _mediaSceneTitleMap;
}

- (NSDictionary<NSNumber *,NSString *> *)mediaSceneDetailMap {
  if (!_mediaSceneDetailMap) {
    
  }
  return _mediaSceneDetailMap;
}

- (NSDictionary<NSNumber *,NSString *> *)mediaSceneClassNameMap {
  if (!_mediaSceneClassNameMap) {
    _mediaSceneClassNameMap = @{
      @(MediaSceneTypeVideoDeviceManagment) : @"SceneVCVideoDevice",
      @(MediaSceneTypeVideoCapture) : @"SceneVCVideoCapture",
      @(MediaSceneTypeVideoRenderOpenGLES) : @"SceneVCVideoRenderOpenGLES",
      @(MediaSceneTypeVideoRenderMetal) : @"",
      @(MediaSceneTypeVideoEncodeHardware) : @"",
      @(MediaSceneTypeVideoDecodeHardware) : @"",
      @(MediaSceneTypeAudioSessionManagment) : @"",
      @(MediaSceneTypeAudioDeviceManagment) : @"",
      @(MediaSceneTypeAudioCapture) : @"",
      @(MediaSceneTypeAudioRender) : @"",
    };
  }
  return _mediaSceneClassNameMap;
}

@end
