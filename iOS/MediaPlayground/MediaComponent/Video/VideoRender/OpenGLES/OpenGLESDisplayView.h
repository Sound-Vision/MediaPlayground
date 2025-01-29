//
//  OpenGLESDisplayView.h
//  
//
//  Created by viva on 2021/7/17.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>

@interface OpenGLESDisplayView : UIView

- (instancetype)initWithFrame:(CGRect)frame context:(EAGLContext*)context;
- (GLuint)getFrameBufferId;
- (GLint)getBackingWidth;
- (GLint)getBackingHeight;

@end
