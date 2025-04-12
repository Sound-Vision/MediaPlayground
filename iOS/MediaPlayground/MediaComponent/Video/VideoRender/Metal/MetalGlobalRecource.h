//
//  MetalGlobalRecource.h
//  MediaPlayground
//
//  Created by Viva on 2025/4/12.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@interface MetalGlobalRecource : NSObject

+ (instancetype)sharedInstance;

- (id<MTLDevice>)getDevice;

- (id<MTLLibrary>)getDefaultLibrary;

- (id<MTLCommandQueue>) getCommandQueue;

@end

NS_ASSUME_NONNULL_END
