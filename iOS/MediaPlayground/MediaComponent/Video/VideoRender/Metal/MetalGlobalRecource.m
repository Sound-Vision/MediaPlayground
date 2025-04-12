//
//  MetalGlobalRecource.m
//  MediaPlayground
//
//  Created by Viva on 2025/4/12.
//

#import "MetalGlobalRecource.h"

@interface MetalGlobalRecource ()

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLLibrary> default_library;
@property (nonatomic, strong) id<MTLCommandQueue> command_queue;

@end

@implementation MetalGlobalRecource

+ (instancetype)sharedInstance {
  static MetalGlobalRecource* resource = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    resource = [[MetalGlobalRecource alloc] init];
  });
  return resource;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _device = MTLCreateSystemDefaultDevice();
    _default_library = [_device newDefaultLibrary];
    _command_queue = [_device newCommandQueue];
  }
  return self;
}

- (id<MTLDevice>)getDevice {
  return _device;
}

- (id<MTLLibrary>)getDefaultLibrary {
  return _default_library;
}

- (id<MTLCommandQueue>)getCommandQueue {
  return _command_queue;
}

@end
