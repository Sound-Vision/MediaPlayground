//
//  OpenGLESShaderProgram.cpp
//  
//
//  Created by viva on 2021/7/17.
//

#include "OpenGLESShaderProgram.h"

#include <stdio.h>

#pragma mark - Public

OpenGLESShaderProgram::~OpenGLESShaderProgram() {
  Release();
}

int OpenGLESShaderProgram::InitShader(const char* vertex_shader, const char* fragment_shader) {
  if (shader_program_id_ != 0) {
    return VIDEO_RENDER_RESULT_OK;
  }
  
  if (vertex_shader == nullptr || fragment_shader == nullptr) {
    return VIDEO_RENDER_RESULT_ERROR_PARAMETER;
  }
  
  int result = VIDEO_RENDER_RESULT_OK;
  
  result = LoadShader(vertex_shader, GL_VERTEX_SHADER, &vertex_shader_id_);
  if (result != VIDEO_RENDER_RESULT_OK) {
    return VIDEO_RENDER_RESULT_ERROR_SHADER;
  }
  
  result = LoadShader(fragment_shader, GL_FRAGMENT_SHADER, &fragment_shader_id_);
  if (result != VIDEO_RENDER_RESULT_OK) {
    glDeleteShader(vertex_shader_id_);
    vertex_shader_id_ = 0;

    return VIDEO_RENDER_RESULT_ERROR_SHADER;
  }
  
  shader_program_id_ = glCreateProgram();
  if (shader_program_id_ == 0) {
    glDeleteShader(vertex_shader_id_);
    glDeleteShader(fragment_shader_id_);
    vertex_shader_id_ = 0;
    fragment_shader_id_ = 0;

    return VIDEO_RENDER_RESULT_ERROR_SHADER;
  }
  
  glAttachShader(shader_program_id_, vertex_shader_id_);
  glAttachShader(shader_program_id_, fragment_shader_id_);
  
  glLinkProgram(shader_program_id_);
  GLint linked;
  glGetProgramiv(shader_program_id_, GL_LINK_STATUS, &linked);
  if (linked == 0) {
    glDetachShader(shader_program_id_, vertex_shader_id_);
    glDetachShader(shader_program_id_, fragment_shader_id_);
    glDeleteProgram(shader_program_id_);
    glDeleteShader(vertex_shader_id_);
    glDeleteShader(fragment_shader_id_);
    shader_program_id_ = 0;
    vertex_shader_id_ = 0;
    fragment_shader_id_ = 0;
    
    return VIDEO_RENDER_RESULT_ERROR_SHADER;
  }
  
  return VIDEO_RENDER_RESULT_OK;
}

int OpenGLESShaderProgram::StartProgram() {
  glUseProgram(shader_program_id_);
  
  return VIDEO_RENDER_RESULT_OK;
}

int OpenGLESShaderProgram::StopProgram() {
  glUseProgram(0);
  
  return VIDEO_RENDER_RESULT_OK;
}

int OpenGLESShaderProgram::SetMatrix(const char* name, GLfloat* value) {
  if ((name == nullptr) || (value == nullptr)) {
    return VIDEO_RENDER_RESULT_ERROR_PARAMETER;
  }
  
  if (shader_program_id_ == 0) {
    return VIDEO_RENDER_RESULT_ERROR_CALLORDER;
  }
  
  int location = glGetUniformLocation(shader_program_id_, name);
  if (location == -1) {
    return VIDEO_RENDER_RESULT_ERROR_PARAMETER;
  }
  
  glUniformMatrix4fv(location, 1, GL_FALSE, value);
  
  return VIDEO_RENDER_RESULT_OK;
}

int OpenGLESShaderProgram::SetVector(const char* name, GLfloat* value) {
  if ((name == nullptr) || (value == nullptr)) {
    return VIDEO_RENDER_RESULT_ERROR_PARAMETER;
  }
  
  if (shader_program_id_ == 0) {
    return VIDEO_RENDER_RESULT_ERROR_CALLORDER;
  }
  
  int location = glGetUniformLocation(shader_program_id_, name);
  if (location == -1) {
    return VIDEO_RENDER_RESULT_ERROR_PARAMETER;
  }
  
  glUniform4f(location, value[0], value[1], value[2], value[3]);
  
  return VIDEO_RENDER_RESULT_OK;
}

int OpenGLESShaderProgram::SetInt(const char* name, GLint value) {
  if (name == nullptr) {
    return VIDEO_RENDER_RESULT_ERROR_PARAMETER;
  }
  
  if (shader_program_id_ == 0) {
    return VIDEO_RENDER_RESULT_ERROR_CALLORDER;
  }
  
  int location = glGetUniformLocation(shader_program_id_, name);
  if (location == -1) {
    return VIDEO_RENDER_RESULT_ERROR_PARAMETER;
  }
  
  glUniform1i(location, value);
  
  return VIDEO_RENDER_RESULT_OK;
}

int OpenGLESShaderProgram::SetFloat(const char* name, GLfloat value) {
  if (name == nullptr) {
    return VIDEO_RENDER_RESULT_ERROR_PARAMETER;
  }
  
  if (shader_program_id_ == 0) {
    return VIDEO_RENDER_RESULT_ERROR_CALLORDER;
  }
  
  int location = glGetUniformLocation(shader_program_id_, name);
  if (location == -1) {
    return VIDEO_RENDER_RESULT_ERROR_PARAMETER;
  }
  
  glUniform1f(location, value);
  
  return VIDEO_RENDER_RESULT_OK;
}

int OpenGLESShaderProgram::SetTexture(const char* name, uint32_t texture_layer, GLuint texture_id) {
  if (name == nullptr) {
    return VIDEO_RENDER_RESULT_ERROR_PARAMETER;
  }
  
  if (shader_program_id_ == 0) {
    return VIDEO_RENDER_RESULT_ERROR_CALLORDER;
  }
  
  glActiveTexture(GL_TEXTURE0 + texture_layer);
  
  glBindTexture(GL_TEXTURE_2D, texture_id);
  
  int location = glGetUniformLocation(shader_program_id_, name);
  if (location == -1) {
    return VIDEO_RENDER_RESULT_ERROR_PARAMETER;
  }
  
  glUniform1i(location, texture_layer);
  
  return VIDEO_RENDER_RESULT_OK;
}

int OpenGLESShaderProgram::GetAttribLocation(const char* name, int* location) {
  if((name == nullptr) || (location == nullptr)) {
    return VIDEO_RENDER_RESULT_ERROR_PARAMETER;
  }

  if (shader_program_id_ == 0) {
    return VIDEO_RENDER_RESULT_ERROR_CALLORDER;
  }

  *location = glGetAttribLocation(shader_program_id_, name);

  return VIDEO_RENDER_RESULT_OK;
}

#pragma mark - Private

int OpenGLESShaderProgram::LoadShader(const char* shader_source, GLenum type, GLuint* shader) {
  GLuint shader_id = 0;
  shader_id = glCreateShader(type);
  glShaderSource(shader_id, 1, &shader_source, NULL);
  glCompileShader(shader_id);
  GLint compiled = 0;
  glGetShaderiv(shader_id, GL_COMPILE_STATUS, &compiled);
  if (compiled == 0) {
    GLint log_length = 0;
    glGetShaderiv(shader_id, GL_INFO_LOG_LENGTH, &log_length);
    if(log_length > 0) {
      GLchar* log = new (std::nothrow) GLchar [log_length];
      if (log == nullptr) {
        return VIDEO_RENDER_RESULT_ERROR_MEMORY;
      }
      glGetShaderInfoLog(shader_id, log_length, &log_length, log);
      printf("\n OpenGLESShaderProgram Compile Log = %s \n", log);
      delete []log;
    }
    
    glDeleteShader(shader_id);
    
    return VIDEO_RENDER_RESULT_ERROR_SHADER;
  }

  *shader = shader_id;

  return VIDEO_RENDER_RESULT_OK;
}

void OpenGLESShaderProgram::Release() {
  if (shader_program_id_ != 0) {
    glDetachShader(shader_program_id_, vertex_shader_id_);
    glDetachShader(shader_program_id_, fragment_shader_id_);
    glDeleteProgram(shader_program_id_);
  }
  
  if (vertex_shader_id_ != 0) {
    glDeleteShader(vertex_shader_id_);
  }
  
  if (fragment_shader_id_ != 0) {
    glDeleteShader(fragment_shader_id_);
  }
}
