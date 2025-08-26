#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
/*
 *  Tip:
 *  (Vert)
 *  WorldNormal : = TransformObjectToWorldNormal(input.normalOS)
 *  WorldPosition :  TransformObjectToWorld(input.positionOS.xyz)
 * 
 */

//Get Gradient
float4 Gradient(float4 Color1, float4 Color2 , float offset,float2 uv)
 {
     float4 col = lerp(Color1,Color2, uv.y * offset );
     return col;
 }

//Get Base CelShader
float4 BaseCelShader(float4 MainLight,float3 VertexNormal,float4 ColorA,float4 ColorB,float Range , float ShadowPower)
{
    float4 col;
    col = step(Range,saturate(dot(MainLight,VertexNormal)))*ColorA + ColorB + ShadowPower;
    return col;
}


//AdditionalLightFucntion
void AllAdditionalLightPass(float3 WorldPosition,float3 WorldNormal,float2 CutoffThreshold,out float3 LightColor)
{
    LightColor = 0.0f;

    float3 COLOR;
    int lightcount  = GetAdditionalLightsCount();
    for (int i = 0; i < lightcount; i++)
    {
        Light light = GetAdditionalLight(i,WorldPosition);
        COLOR = dot(light.direction,WorldNormal);
        COLOR = smoothstep(CutoffThreshold.x,CutoffThreshold.y,COLOR);
        COLOR *= light.color;
        COLOR *= light.distanceAttenuation;
        LightColor += COLOR;
    }

}

float4 GetFresnel(float3 WorldPositon,float3 VertexNormal,float _min ,float _max,float3 Color)
{
    // float3 worldCameraPos = _WorldSpaceCameraPos;
    // float3 viewDir = normalize(worldCameraPos - WorldPositon);
    //             
    // float4 fresnel = 1-saturate((dot(VertexNormal,viewDir))*Edge);
    // return fresnel;

    float3 worldCameraPos = _WorldSpaceCameraPos;
    float3 viewDir = normalize(worldCameraPos - WorldPositon);
                
    float4 fresnel = 1-saturate(smoothstep(_min,_max,(dot(VertexNormal,viewDir))));
    return fresnel * float4(Color,1);
}

