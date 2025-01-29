//
//  VideoCapturer.h
//  MediaPlayground
//
//  Created by Viva on 2024/12/28.
//

#import <Foundation/Foundation.h>
#import "VideoCaptureDefine.h"

@protocol VideoCapturerDelegate <NSObject>

@optional
- (void)didCaptureVideoFrameWithSampleBuffer:(CMSampleBufferRef)sample_buffer width:(NSUInteger)width height:(NSUInteger)height;
- (void)didCaptureVideoFrameWithDataBuffer:(NSData*)data_buffer width:(NSUInteger)width height:(NSUInteger)height;
- (void)didFinishConfigurationWithPreviewLayer:(AVCaptureVideoPreviewLayer *)preview_layer;

@end

@interface VideoCapturer : NSObject

- (void)updateConfig:(VideoCaptureConfig*)config;
- (void)startCapture;
- (void)stopCapture;
- (void)updateDelegate:(id<VideoCapturerDelegate>)delegate;

@end
