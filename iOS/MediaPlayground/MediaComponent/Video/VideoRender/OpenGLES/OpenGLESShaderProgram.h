//
//  OpenGLESShaderProgram.hpp
//  
//
//  Created by viva on 2021/7/17.
//

#ifndef OpenGLESShaderProgram_hpp
#define OpenGLESShaderProgram_hpp

#include "VideoRenderDefine.h"
#include <OpenGLES/ES2/gl.h>

class OpenGLESShaderProgram {
    
public:
  ~OpenGLESShaderProgram();
public:
  /// 初始化着色器
  int InitShader(const char* vertex_shader, const char* fragment_shader);
  /// 启动着色器程序
  int StartProgram();
  /// 停止着色器程序
  int StopProgram();
  /// 将矩阵参数传入着色器
  int SetMatrix(const char* name, GLfloat* value);
  /// 将向量参数传入着色器
  int SetVector(const char* name, GLfloat* value);
  /// 将整型参数传入着色器
  int SetInt(const char* name, GLint value);
  /// 将浮点类型参数传入着色器
  int SetFloat(const char* name, GLfloat value);
  /// 将纹理数据传入着色器
  int SetTexture(const char* name, uint32_t texture_layer, GLuint texture_id);
  /// 获取着色器中参数的位置
  int GetAttribLocation(const char* name, int* location);
private:
  /// 加载着色器
  int LoadShader(const char* shader_source, GLenum type, GLuint* shader);
  /// 释放资源
  void Release();
private:
  /// 着色器程序 id
  GLuint shader_program_id_ = 0;
  /// 顶点着色器 id
  GLuint vertex_shader_id_ = 0;
  /// 片段着色器 id
  GLuint fragment_shader_id_ = 0;
};

#endif /* OpenGLESShaderProgram_hpp */
