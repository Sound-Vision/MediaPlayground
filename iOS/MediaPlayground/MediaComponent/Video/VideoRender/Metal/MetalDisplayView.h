//
//  MetalDisplayView.h
//  
//
//  Created by Viva on 2023/8/12.
//


#ifdef PLATFORM_IOS

#define VIEW_CLASS UIView

#import <UIKit/UIKit.h>

#endif


#ifdef PLATFORM_MAC

#define VIEW_CLASS NSView

#import <AppKit/AppKit.h>
#import <QuartzCore/CAMetalLayer.h>

#endif

@interface MetalDisplayView : VIEW_CLASS

- (CAMetalLayer *)getMetalLayer;

#ifdef PLATFORM_MAC
- (void)configLayerWithDevice:(id<MTLDevice>)device pixelFormat:(MTLPixelFormat)pixelFormat;
#endif

@end
