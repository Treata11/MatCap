//
//  Exposure.metal
//  MatCap
//
//  Created by Treata Norouzi on 2/10/25.
//

#include <metal_stdlib>
using namespace metal;


[[ stitchable ]] half4 multiply(float2 position, half4 color, float value) { return fmin(color * value, 1); }

[[ stitchable ]] half4 toBGR(float2 position, half4 color) { return color.bgra; }
