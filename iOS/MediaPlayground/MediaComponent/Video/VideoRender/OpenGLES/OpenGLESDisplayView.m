//
//  OpenGLESDisplayView.m
//  
//
//  Created by viva on 2021/7/17.
//

#import "OpenGLESDisplayView.h"

@interface OpenGLESDisplayView ()

@property (nonatomic, strong) EAGLContext* context;
@property (nonatomic, assign) CGSize current_size;

@end

@implementation OpenGLESDisplayView {
  GLuint frame_buffer_id_;
  GLuint render_buffer_id_;
  
  GLint backing_width_;
  GLint backing_height_;
}

#pragma mark - Override

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void)dealloc {
  [self destroyRenderResource];
}

- (void)layoutSubviews {
  if (!CGSizeEqualToSize(self.current_size, self.frame.size)) {
      [self destroyRenderResource];
      [self createRenderResource];
      self.current_size = self.frame.size;
  }
  
  [super layoutSubviews];
}

#pragma mark - Public

- (instancetype)initWithFrame:(CGRect)frame context:(EAGLContext *)context {
  self = [super initWithFrame:frame];
  if (self) {
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.context = context;
    self.current_size = frame.size;
    [self createRenderResource];
  }
  return self;
}

- (GLuint)getFrameBufferId {
  return frame_buffer_id_;
}

- (GLint)getBackingWidth {
  return backing_width_;
}

- (GLint)getBackingHeight {
  return backing_height_;
}

#pragma mark - Private

- (void)createRenderResource {
  CAEAGLLayer *eagl_layer = (CAEAGLLayer *)self.layer;
  eagl_layer.opaque = YES;
  eagl_layer.contentsScale = [UIScreen mainScreen].scale;
  eagl_layer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking:@YES};
    
  [EAGLContext setCurrentContext:self.context];
  
  glGenRenderbuffers(1, &render_buffer_id_);
  glBindRenderbuffer(GL_RENDERBUFFER, render_buffer_id_);
  [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:eagl_layer];
  
  glGenFramebuffers(1, &frame_buffer_id_);
  glBindFramebuffer(GL_FRAMEBUFFER, frame_buffer_id_);
  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, render_buffer_id_);
  
  glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backing_width_);
  glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backing_height_);
}

- (void)destroyRenderResource {
  if (self.context) {
    [EAGLContext setCurrentContext:self.context];
    
    if (render_buffer_id_ != 0) {
        glDeleteRenderbuffers(1, &render_buffer_id_);
    }
    
    if (frame_buffer_id_ != 0) {
        glDeleteFramebuffers(1, &frame_buffer_id_);
    }
  }
}

@end
