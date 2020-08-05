//
//  Shaders.metal
//  MetalHeatMap
//
//  Created by Douglas Webster on 8/1/20.
//  Copyright © 2020 Douglas Webster. All rights reserved.
//

#include <metal_stdlib>
#include "ShaderDefinitions.h"
using namespace metal;

struct VertexOut {
    float4 pos [[ position ]];
    float4 color;
    float size [[ point_size ]];
};

/**
 The first parameter is the position of each vertex
 The [[ buffer(0) ]] specifies to the vertex shader to pull its data from the first vertex buffer sent to the shader
 The second parameter is the index of the vertex within the vertex array
 */
vertex VertexOut vertex_shader(
    const device Vertex* vertex_array [[ buffer(0) ]],
    unsigned int vid [[ vertex_id ]]) {
    Vertex in = vertex_array[vid];
    VertexOut out;
    out.pos = float4(in.pos.x, in.pos.y, 0, 1);
    out.color = in.color;
    out.size = 10;
    return out;
}

fragment float4 fragment_shader(VertexOut interpolated [[ stage_in ]]) {
    return interpolated.color;
}
