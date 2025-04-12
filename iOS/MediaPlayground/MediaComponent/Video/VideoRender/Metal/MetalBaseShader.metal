//
//  MetalBaseShader.metal
//  
//
//  Created by Viva on 2023/8/12.
//

// [[xxx]]是C++标准中的属性限定符。
// [[position]]指定了哪个变量为顶点坐标；若返回的结果中封装了顶点坐标，需要用限定符进行说明。
// [[vertex_id]]指定了顶点索引，直接使用即可。
// [[buffer(index)]]指定了参数的来源，参考commandEncoder设置参数时的操作。
// [[xxx]]中的名称是Metal框架内定的，不能修改，但是像buffer(index)中的index这类变量的名称可以自定义。

#include <metal_stdlib>
#include "MetalShaderDefine.h"

using namespace metal;

struct PositionData {
    float4 vertexCoordinates [[position]];
    float2 textureCoordinates;
};

///<基础顶点着色器
vertex PositionData BasicVertexShader(uint vertexID [[vertex_id]],
                                        constant float2 *pPosition [[buffer(MetalShaderIndexVertexCoordinates)]],
                                        constant float2 *pTexCoord [[buffer(MetalShaderIndexTextureCoordinates)]]) {
  PositionData out;
  out.vertexCoordinates.xy = pPosition[vertexID];
  out.vertexCoordinates.z = 0.0;
  out.vertexCoordinates.w = 1.0;
  out.textureCoordinates = pTexCoord[vertexID];
  return out;
}

///<RGBA片段着色器
fragment float4 RGBAFragmentShader(PositionData in [[stage_in]],
                                   texture2d<float> texture [[texture(MetalShaderTextureIndex0)]]) {
  constexpr sampler textureSampler (mag_filter::linear,
                                    min_filter::linear);
  
  float4 color = texture.sample(textureSampler, in.textureCoordinates);
  
  return color;
}

///<NV12片段着色器
fragment float4 NV12FragmentShader(PositionData in [[stage_in]],
                                   texture2d<float> Ytexture [[texture(MetalShaderTextureIndex0)]],
                                   texture2d<float> UVtexture [[texture(MetalShaderTextureIndex1)]])
{
  constexpr sampler textureSampler (mag_filter::linear,
                                    min_filter::linear);
  float y, u, v, r, g, b;
  y = Ytexture.sample(textureSampler, in.textureCoordinates).x;
  u = UVtexture.sample(textureSampler, in.textureCoordinates).x;
  v = UVtexture.sample(textureSampler, in.textureCoordinates).y;
  y = 1.1643 * (y - 0.0625);
  u = u - 0.5;
  v = v - 0.5;
  r = y + 1.5958 * v;
  g = y - 0.39173 * u - 0.81290 * v;
  b = y + 2.017 * u;
  
  float4 color = float4(r, g, b, 1.0);
  
  return color;
}
