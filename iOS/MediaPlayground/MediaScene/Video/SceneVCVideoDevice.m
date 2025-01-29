//
//  SceneVCVideoDevice.m
//  MediaPlayground
//
//  Created by Viva on 2024/12/28.
//

#import "SceneVCVideoDevice.h"
#import "VideoDeviceInfoCollector.h"

static NSString* const kDeviceInfoViewCellID = @"kDeviceInfoViewCellID";
static NSString* const kFormatInfoViewCellID = @"kFormatInfoViewCellID";
static NSString* const kFormatDetailViewCellID = @"kFormatDetailViewCellID";

@interface SceneVCVideoDevice ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView* deviceInfoView;
@property (nonatomic, strong) UITableView* formatInfoView;
@property (nonatomic, strong) UITableView* formatDetailView;
@property (nonatomic, strong) NSArray<AVCaptureDevice*>* deviceList;
@property (nonatomic, strong) NSArray<AVCaptureDeviceFormat*>* formatList;
@property (nonatomic, strong) NSArray<NSString*>* formatDetailList;

@end

@implementation SceneVCVideoDevice

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self setupSubView];
  
  NSArray* deviceTypeList = @[AVCaptureDeviceTypeBuiltInWideAngleCamera];
  self.deviceList = [VideoDeviceInfoCollector getDeviceListWithDeviceTypeList:deviceTypeList];
}

- (void)setupSubView {
  CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
  CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
  
  CGFloat topOffset = 120;
  CGFloat bottomOffset = 40;
  CGFloat validHeight = screenHeight - topOffset - bottomOffset;
  
  self.deviceInfoView.frame = CGRectMake(0, topOffset, screenWidth, validHeight/4);
  self.formatInfoView.frame = CGRectMake(0, topOffset + validHeight/4, screenWidth, validHeight/2);
  self.formatDetailView.frame = CGRectMake(0, topOffset + validHeight/4*3, screenWidth, validHeight/4);
  
  [self.view addSubview:self.deviceInfoView];
  [self.view addSubview:self.formatInfoView];
  [self.view addSubview:self.formatDetailView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (tableView == self.deviceInfoView) {
    return self.deviceList.count;
  } else if (tableView == self.formatInfoView) {
    return self.formatList.count;
  } else if (tableView == self.formatDetailView) {
    return self.formatDetailList.count;
  }
  return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell* cell = nil;
  if (tableView == self.deviceInfoView) {
    cell = [tableView dequeueReusableCellWithIdentifier:kDeviceInfoViewCellID forIndexPath:indexPath];
    if (!cell) {
      cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kDeviceInfoViewCellID];
    }
    AVCaptureDevice* device = [self.deviceList objectAtIndex:indexPath.row];
    cell.textLabel.text = [VideoDeviceInfoCollector getDescriptionForDevice:device];
  } else if (tableView == self.formatInfoView) {
    cell = [tableView dequeueReusableCellWithIdentifier:kFormatInfoViewCellID forIndexPath:indexPath];
    if (!cell) {
      cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kFormatInfoViewCellID];
    }
    AVCaptureDeviceFormat* format = [self.formatList objectAtIndex:indexPath.row];
    cell.textLabel.text = [VideoDeviceInfoCollector getDescriptionForFormat:format];
  } else if (tableView == self.formatDetailView) {
    cell = [tableView dequeueReusableCellWithIdentifier:kFormatDetailViewCellID forIndexPath:indexPath];
    if (!cell) {
      cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kFormatDetailViewCellID];
    }
    NSString* formatDetail = [self.formatDetailList objectAtIndex:indexPath.row];
    cell.textLabel.text = formatDetail;
  }
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (tableView == self.deviceInfoView) {
    AVCaptureDevice* device = [self.deviceList objectAtIndex:indexPath.row];
    NSString* deviceDescription = [VideoDeviceInfoCollector getDescriptionForDevice:device];
    NSLog(@"device:%@", deviceDescription);
    self.formatList = [VideoDeviceInfoCollector getFormatListWithDevice:device];
    [self.formatInfoView reloadData];
  } else if (tableView == self.formatInfoView) {
    AVCaptureDeviceFormat* format = [self.formatList objectAtIndex:indexPath.row];
    NSString* formatDescription = [VideoDeviceInfoCollector getDescriptionForFormat:format];
    NSLog(@"format:%@", formatDescription);
    self.formatDetailList = [VideoDeviceInfoCollector getDetailListForFormat:format];
    [self.formatDetailView reloadData];
  }
}

- (UITableView *)deviceInfoView {
  if (!_deviceInfoView) {
    _deviceInfoView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    [_deviceInfoView registerClass:[UITableViewCell class] forCellReuseIdentifier:kDeviceInfoViewCellID];
    _deviceInfoView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    _deviceInfoView.dataSource = self;
    _deviceInfoView.delegate = self;
  }
  return _deviceInfoView;
}

- (UITableView *)formatInfoView {
  if (!_formatInfoView) {
    _formatInfoView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    [_formatInfoView registerClass:[UITableViewCell class] forCellReuseIdentifier:kFormatInfoViewCellID];
    _formatInfoView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    _formatInfoView.dataSource = self;
    _formatInfoView.delegate = self;
  }
  return _formatInfoView;
}

- (UITableView *)formatDetailView {
  if (!_formatDetailView) {
    _formatDetailView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    [_formatDetailView registerClass:[UITableViewCell class] forCellReuseIdentifier:kFormatDetailViewCellID];
    _formatDetailView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    _formatDetailView.dataSource = self;
    _formatDetailView.delegate = self;
  }
  return _formatDetailView;
}
  
@end
