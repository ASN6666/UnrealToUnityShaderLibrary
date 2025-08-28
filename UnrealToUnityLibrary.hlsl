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
float4 BaseCelShader(float4 MainLight,float3 VertexNormal,float4 ColorA,float4 ColorB,float Range , float ShadowPower,out float4 col)
{
    col = (step(Range,saturate(dot(MainLight,VertexNormal)*0.5+0.5))*ColorA + ColorB + ShadowPower);
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
        //COLOR = smoothstep(.4,.7,COLOR);
        COLOR = smoothstep(CutoffThreshold.x,CutoffThreshold.y,COLOR);
        COLOR *= light.color;
        COLOR *= light.distanceAttenuation;
        LightColor += COLOR;
    }

}

float4 GetFresnel(float3 WorldPositon,float3 VertexNormal,float _min ,float _max,float3 FrontColor,float3 BackColor)
{
    float halfLamber_NoL = 0.5 * dot(VertexNormal, _MainLightPosition) + 0.5;
    float NhalfLamber_NoL = 0.5 * -dot(VertexNormal, _MainLightPosition) + 0.5;
    float3 worldCameraPos = _WorldSpaceCameraPos;
    float3 viewDir = normalize(worldCameraPos - WorldPositon);
                
    float4 fresnel = 1-saturate(smoothstep(_min,_max,(dot(VertexNormal,viewDir))));
    float4 rimLgihtArea_Dir = saturate( halfLamber_NoL -.5);
    float4 NrimLgihtArea_Dir = saturate( NhalfLamber_NoL - .5) ;
    rimLgihtArea_Dir  *= fresnel * float4((FrontColor),1);
    NrimLgihtArea_Dir *= fresnel * float4((BackColor),1);
    return NrimLgihtArea_Dir + rimLgihtArea_Dir;
    //return  rimLgihtArea_Dir  * fresnel * float4((FrontColor),1);

    
}

void GetOutline(float3 position,float3 normal,float outline,out float3 Result)
{
    //vert
    Result = position.xyz + normal * outline;
}

void SetSDF(sampler2D _SDFTex,float2 uv,out float4 result)
{
    float3 _forwardVec = unity_ObjectToWorld._m02_m12_m22;
    float3 _SideVec = unity_ObjectToWorld._m00_m10_m20;

    //取得向上向量
    float3 upVector = cross(_forwardVec, _SideVec);
    //dot(陽光方向，向上方向) 
    float3 LpU = dot(_MainLightPosition, upVector)/pow(length(upVector), 2) * upVector;
    float3 LpHeadHorizon = _MainLightPosition - LpU;
    float value = acos(dot(normalize(LpHeadHorizon), normalize(_SideVec)))/3.142;
    float exposeRight = step(value, 0.5);//計算光照閾值
    
    float valueR = pow(1 - value * 2, 3);
    float valueL = pow(value * 2 - 1, 3);
    float mixValue = lerp(valueL, valueR, exposeRight);
    float sdfRembrandtLeft = tex2D(_SDFTex, float2(1 - uv.x, uv.y)).r;
    float sdfRembrandtRight = tex2D(_SDFTex, uv).r;
    float mixSdf = lerp(sdfRembrandtRight, sdfRembrandtLeft, exposeRight);
                    
    float sdf = step(mixValue, mixSdf);
    sdf *= 2.5;//顏色校正
    sdf = lerp(0, sdf  , step(0, dot(normalize(LpHeadHorizon), normalize(_forwardVec))));
    result = sdf;
}
