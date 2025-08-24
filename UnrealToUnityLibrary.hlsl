#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

//Get Gradiegnt
float4 Gradient(float4 Color1, float4 Color2 , float offset,float2 uv)
 {
     float4 col = lerp(Color1,Color2, uv.y * offset );
     return col;
 }

//Get Base CelShader
float4 BaseCelShader(float4 MainLight,float3 VertexNormal,float4 ColorA,float4 ColorB,float Range , float ShadowPower)
{
    float4 col;
    col = saturate(step(Range,dot(MainLight,VertexNormal))+ ShadowPower);
    return col;
}
