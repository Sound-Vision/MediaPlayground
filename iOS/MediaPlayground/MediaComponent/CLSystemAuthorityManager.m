//
//  CLSystemAuthorityManager.m
//  CLKit
//
//  Created by viva on 2018/4/5.
//  Copyright © 2018年 viva. All rights reserved.
//

#import "CLSystemAuthorityManager.h"

#import <Photos/Photos.h>
#import <AVFoundation/AVCaptureDevice.h>

@implementation CLSystemAuthorityManager

//检查相册的访问权限
+ (void)checkPhotoLibraryAuthorizationWithAuthorizedHandler:(void(^)(void))authorizedHandler
                                          restrictedHandler:(void(^)(void))restrictedHandler
                                              deniedHandler:(void(^)(void))deniedHandler {
    void(^completionHandler)(PHAuthorizationStatus status) = ^(PHAuthorizationStatus status) {
        NSLog(@"PhotoLibraryAuthorizationStatus = %ld", (long)status);
        
        [CLSystemAuthorityManager checkPhotoLibraryAuthorizationWithAuthorizedHandler:authorizedHandler
                                                                    restrictedHandler:restrictedHandler
                                                                        deniedHandler:deniedHandler];
    };
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    switch (status) {
        case PHAuthorizationStatusNotDetermined: {
            [PHPhotoLibrary requestAuthorization:completionHandler];
            
            break;
        }
        case PHAuthorizationStatusAuthorized: {
            //app被允许访问系统相册
            if (authorizedHandler) {
                authorizedHandler();
            }
            
            break;
        }
        case PHAuthorizationStatusRestricted: {
            //app被禁止访问系统相册，有可能是家长权限
            if (restrictedHandler) {
                restrictedHandler();
            }
            
            break;
        }
        case PHAuthorizationStatusDenied: {
            //用户拒绝了app访问系统相册的要求
            if (deniedHandler) {
                deniedHandler();
            }
            
            break;
        }
            
        default:
            break;
    }
}

//检查相机的访问权限
+ (void)checkCameraAuthorizationWithAuthorizedHandler:(void(^)(void))authorizedHandler
                                    restrictedHandler:(void(^)(void))restrictedHandler
                                        deniedHandler:(void(^)(void))deniedHandler {
    void(^completionHandler)(BOOL granted) = ^(BOOL granted) {
        NSLog(@"CameraAuthorizationStatus = %d", granted);
        
        [CLSystemAuthorityManager checkCameraAuthorizationWithAuthorizedHandler:authorizedHandler
                                                              restrictedHandler:restrictedHandler
                                                                  deniedHandler:deniedHandler];
    };
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (status) {
        case AVAuthorizationStatusNotDetermined: {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:completionHandler];
            
            break;
        }
        case AVAuthorizationStatusAuthorized: {
            //app被允许访问系统相册
            if (authorizedHandler) {
                authorizedHandler();
            }
            
            break;
        }
        case AVAuthorizationStatusRestricted: {
            //app被禁止访问系统相册，有可能是家长权限
            if (restrictedHandler) {
                restrictedHandler();
            }
            
            break;
        }
        case AVAuthorizationStatusDenied: {
            //用户拒绝了app访问系统相册的要求
            if (deniedHandler) {
                deniedHandler();
            }
            
            break;
        }
            
        default:
            break;
    }
}

//检查麦克风的访问权限
+ (void)checkMicrophoneAuthorizationWithAuthorizedHandler:(void(^)(void))authorizedHandler
                                        restrictedHandler:(void(^)(void))restrictedHandler
                                            deniedHandler:(void(^)(void))deniedHandler {
    void(^completionHandler)(BOOL granted) = ^(BOOL granted) {
        NSLog(@"MicrophoneAuthorizationStatus = %d", granted);
        
        [CLSystemAuthorityManager checkMicrophoneAuthorizationWithAuthorizedHandler:authorizedHandler
                                                                  restrictedHandler:restrictedHandler
                                                                      deniedHandler:deniedHandler];
    };
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    switch (status) {
        case AVAuthorizationStatusNotDetermined: {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:completionHandler];
            
            break;
        }
        case AVAuthorizationStatusAuthorized: {
            //app被允许访问系统相册
            if (authorizedHandler) {
                authorizedHandler();
            }
            
            break;
        }
        case AVAuthorizationStatusRestricted: {
            //app被禁止访问系统相册，有可能是家长权限
            if (restrictedHandler) {
                restrictedHandler();
            }
            
            break;
        }
        case AVAuthorizationStatusDenied: {
            //用户拒绝了app访问系统相册的要求
            if (deniedHandler) {
                deniedHandler();
            }
            
            break;
        }
            
        default:
            break;
    }
}

@end
