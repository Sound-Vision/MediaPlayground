//
//  VideoRendererMetal.h
//  MediaPlayground
//
//  Created by Viva on 2025/4/12.
//

#import <UIKit/UIKit.h>
#import <CoreVideo/CoreVideo.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoRendererMetal : NSObject

- (void)attachNativeView:(UIView*)native_view;
- (void)renderVideoFrameWithData:(void*)data width:(NSUInteger)width height:(NSUInteger)height;
- (void)renderVideoFrameWithPixelBuffer:(CVPixelBufferRef)pixel_buffer width:(NSUInteger)width height:(NSUInteger)height;

@end

NS_ASSUME_NONNULL_END
