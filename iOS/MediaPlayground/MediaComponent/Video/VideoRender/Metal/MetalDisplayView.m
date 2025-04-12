//
//  MetalDisplayView.m
//  
//
//  Created by Viva on 2023/8/12.
//

#import "MetalDisplayView.h"


@interface MetalDisplayView ()

@property (nonatomic, strong) CAMetalLayer* metal_layer;

@end


#ifdef PLATFORM_IOS

@implementation MetalDisplayView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.metal_layer = (CAMetalLayer*)self.layer;
    self.metal_layer.contentsScale = [UIScreen mainScreen].scale;
  }
  
  return self;
}

+ (Class)layerClass {
    return [CAMetalLayer class];
}

- (CAMetalLayer *)getMetalLayer {
    return self.metal_layer;
}

@end

#endif


#ifdef PLATFORM_MAC

@implementation MetalDisplayView

- (instancetype)initWithFrame:(NSRect)frameRect {
  self = [super initWithFrame:frameRect];
  if (self) {
    _metalLayer = [CAMetalLayer layer];
    [self setLayer:_metalLayer];
    [self setWantsLayer:YES];
  }
  
  return self;
}

- (void)configLayerWithDevice:(id<MTLDevice>)device pixelFormat:(MTLPixelFormat)pixelFormat {
  self.metalLayer.device = device;
  self.metalLayer.pixelFormat = pixelFormat;
}

- (CAMetalLayer *)getMetalLayer {
  return self.metalLayer;
}

@end

#endif
