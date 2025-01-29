//
//  CLSystemAuthorityManager.h
//  CLKit
//
//  Created by viva on 2018/4/5.
//  Copyright © 2018年 viva. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CLSystemAuthorityManager : NSObject

/**
 检查相册的访问权限

 @param authorizedHandler 权限允许的回调
 @param restrictedHandler 权限受限的回调
 @param deniedHandler 权限被拒绝的回调
 */
+ (void)checkPhotoLibraryAuthorizationWithAuthorizedHandler:(void(^)(void))authorizedHandler
                                          restrictedHandler:(void(^)(void))restrictedHandler
                                              deniedHandler:(void(^)(void))deniedHandler;

/**
 检查摄像头的访问权限

 @param authorizedHandler 权限允许的回调
 @param restrictedHandler 权限受限的回调
 @param deniedHandler 权限被拒绝的回调
 */
+ (void)checkCameraAuthorizationWithAuthorizedHandler:(void(^)(void))authorizedHandler
                                    restrictedHandler:(void(^)(void))restrictedHandler
                                        deniedHandler:(void(^)(void))deniedHandler;

/**
 检查麦克风的访问权限
 
 @param authorizedHandler 权限允许的回调
 @param restrictedHandler 权限受限的回调
 @param deniedHandler 权限被拒绝的回调
 */
+ (void)checkMicrophoneAuthorizationWithAuthorizedHandler:(void(^)(void))authorizedHandler
                                        restrictedHandler:(void(^)(void))restrictedHandler
                                            deniedHandler:(void(^)(void))deniedHandler;

@end
