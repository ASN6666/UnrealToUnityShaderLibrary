Shader "Unlit/CelShader"
{
    Properties
    {
        [Enum(UnityEngine.Rendering.CullMode)]_CullMode("CullMode",Float) = 0
        
        [Header(BaseTexture)]
        _MainTex ("Texture", 2D) = "white" {}
        
        [Toggle]_EnableSDF("EnableSDF", float) = 0
        _SDFTex("SDFTexture",2D) = "White" {}
        
        [Toggle]_EnableSSS("EnableSSS", float) = 0
        _SSSTex("SSSTexture",2D) = "White" {}
        
        [Toggle]EnableAlphaMask("EnableAlphaMask",float) = 0
        _AlphaMask("AlphaMask",2D) = "White"{}
        
        [Toggle]EnableILM("EnableILMTexture", Float) = 0
        _ILMTexture("ILMTexture",2D) = "white"
        
        [Toggle]_UseRamp("UseRamp", float) = 0
        _RampTexture("RampTexture",2D) = "White"{}
        
        
        
        [Header(Color)]
        _ColorA("ColorA",Color) = (0,0,0,0)
        _ColorB("ColorB",Color) = (0,0,0,0)
        _Outline("Outline",Float) =.05
        
        [Header(Fresnel)]
        _FrontfresnelColor("FrontfresnelColor",Color) = (1,1,1,1)
        _FresnelTickness("FresnelTickness",Range(0,1)) = 0.012

        
        [Header(AdditionalLight)]
        _AdditionalLightIndensity("AdditionalLightIndensity",Range(0,1)) = 0.5
        _MinAdditionalLightCutOff("MinAdditionalLightCutOff",Float) = 0.9
        _MaxAdditionalLightCutOff("MaxAdditionalLightCutOff",Float) = 0.9
        
        //_forwardVec("ForwardVector",Vector) = (0,0,0,0)
        //_SideVec("SideVector",Vector) = (0,0,0,0)
    }
    SubShader
    {
        
        Tags {"Queue" = "Geometry" "RenderType"="Opaque"}
        Pass
        {
            
            
            Tags { "lightmode" = "UniversalForward" }
            Cull [_CullMode]
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Assets/UnrealToUnityShaderLibrary/UnrealToUnityLibrary.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            
            float4 _CameraDepthTexture_TexelSize;
            
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
                float4 COLOR:COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertexCS : SV_POSITION;
                float3 normal:NORMAL;
                float3 WorldPos:TEXCOORD1;
                float4 COLOR:COLOR;
                float4 POSITIONNDC:TEXCOORD2;
                float3 NORMALVS:TEXCOORD3;
                float3 PositionVS:TEXCOORD4;
                float4 ScreenPos:TEXCOORD5;
                
            };
            
            CBUFFER_START(UnityPerMaterial)
            
            sampler2D _MainTex;
            
            float _EnableSDF;
            sampler2D _SDFTex;
            
            float _EnableSSS;
            sampler2D _SSSTex;

            float EnableILM;
            sampler2D _ILMTexture;
            
            float _UseRamp;
            sampler2D _RampTexture;
            
            float EnableAlphaMask; 
            sampler2D _AlphaMask;
            
            float4 _ColorA;
            float4 _ColorB;
            float4 _MainTex_ST;
            float4 _FrontfresnelColor;
            float4 _BackfresnelColor;
            
            float _AdditionalLightIndensity;
            float _MinAdditionalLightCutOff;
            float _MaxAdditionalLightCutOff;

            vector _forwardVec;
            vector _SideVec;

            float _FresnelTickness;
            CBUFFER_END
            
            v2f vert (appdata v)
            {
               
                v2f o;
                o.vertexCS.xyzw = TransformObjectToHClip(v.vertex.xyzw);
                
                o.normal = TransformObjectToWorldNormal(v.normal);
                o.WorldPos = TransformObjectToWorld(v.vertex.xyz);
                o.uv = v.uv;
                o.COLOR = v.COLOR;
                o.NORMALVS = normalize(mul((float3x3)UNITY_MATRIX_V, TransformObjectToWorldNormal(o.normal)));
               
                float4 screenPos = ComputeScreenPos(o.vertexCS);
                o.POSITIONNDC = (screenPos/screenPos.w)*2 -1;
                o.ScreenPos = ComputeScreenPos(v.vertex);
                return o;
            }
            
            half4 frag (v2f i) : SV_Target
            {   
                float4 ColMaintex;
                //AO
                float4 ILMTex = tex2D(_ILMTexture,i.uv);
                float ILM_R = ILMTex.r ;
                float ILM_G =ILMTex.g;
                float ILM_B = ILMTex.b;
                

                
                if(_EnableSSS)
                {
                    float4 maintex= tex2D(_MainTex,i.uv);
                    float4 sssmaintex =tex2D(_SSSTex,i.uv);
                     ColMaintex = lerp(sssmaintex * maintex, maintex,clamp(length(_MainLightColor.rgb),0.1,.4));
                    
                }
                else
                {
                    ColMaintex =  tex2D(_MainTex,i.uv);
                }
                if(EnableILM == true)
                {
                    ColMaintex += saturate(step((abs(ILM_R - 0.07)),0.05)*ILM_R);
                    ColMaintex += saturate(step((abs(ILM_R - 0.2)),0.05)*ILM_R);
                    ColMaintex = lerp(ColMaintex,ColMaintex * (ILM_G),.5);
                }
                if(EnableAlphaMask == true)
                {
                    float4 altex =  tex2D(_AlphaMask,i.uv);
                   // float4 tex  = tex2D(_AlphaMask,i.uv);
                    clip(altex.a -.5) ;
                    return altex;
                }
                if(_EnableSDF == false )
                {   
                    if(_UseRamp == true)
                    {
                        float NdotL = dot(_MainLightPosition,i.normal);
                        float NDotLLength = length(NdotL);
                        float3 ramp= tex2D(_RampTexture,float2(i.uv.x,i.uv.y * .1+1)).rgb;
                        return float4(ramp,1);
                    }
                    float3 AdditionalLightcolor;
                    float4 Cel;
                    
                    BaseCelShader(_MainLightPosition,i.normal,_ColorA,_ColorB,.5,0,Cel);
                    AllAdditionalLightPass(i.WorldPos,i.normal,(_MinAdditionalLightCutOff,_MaxAdditionalLightCutOff),AdditionalLightcolor);
                    AdditionalLightcolor = clamp(AdditionalLightcolor,0,_AdditionalLightIndensity);
                   // float4 fresnel= GetFresnel(i.WorldPos,i.normal,.5,.5,_FrontfresnelColor,_BackfresnelColor);
                    //return  ColMaintex * Cel +fresnel + float4(saturate(AdditionalLightcolor),1) + clamp(_MainLightColor ,0.0,0);
                    //return  ColMaintex * Cel  + fresnel + float4(saturate(AdditionalLightcolor),1) + clamp(_MainLightColor ,0.0,0);
                    //return float4(color,1);
                    
                   
                    float3 normalVS =normalize(mul((float3x3)UNITY_MATRIX_V, i.normal));
                    float2 vertexSS_01 = i.POSITIONNDC/2 + 0.5 ;
                    float srcDepth =SampleSceneDepth(vertexSS_01);
                    //float2 vertexSS_01_offset = vertexSS_01 + normalVS.xy * _FresnelTickness *srcDepth *0.01;
                    float2 vertexSS_01_offset = vertexSS_01 + normalVS.xy * _FresnelTickness *srcDepth *0.01;
                    float dstDepth =SampleSceneDepth(vertexSS_01_offset);
                    float srcdepthvalue = Linear01Depth(srcDepth, _ZBufferParams);
                    float dstdepthvalue = Linear01Depth(dstDepth, _ZBufferParams);
                    float3 fresnel= step(0.00001, dstdepthvalue - srcdepthvalue);
                    fresnel *= _FrontfresnelColor;
                    return  ColMaintex * Cel  + float4(fresnel,1) + float4(saturate(AdditionalLightcolor),1) + clamp(_MainLightColor ,0.0,0);
                        

                    return  ColMaintex * Cel  + float4(saturate(AdditionalLightcolor),1) + clamp(_MainLightColor ,0.0,0);
                    
                    
                    
                     }
                    
                else
                {
                    
                    float3 AdditionalLightcolor;
                    AllAdditionalLightPass(i.WorldPos,i.normal,(_MinAdditionalLightCutOff,_MaxAdditionalLightCutOff),AdditionalLightcolor);
                    AdditionalLightcolor = clamp(AdditionalLightcolor,0,_AdditionalLightIndensity);
                    

                    
                    //float4 fresnel= GetFresnel(i.WorldPos,i.normal,_Min,_Max,_FrontfresnelColor,_BackfresnelColor);
                    float4 sdf;
                    SetSDF(_SDFTex,i.uv,sdf);
                    sdf = lerp(sdf,ColMaintex,.7);
                    // return sdf  * ColMaintex * _ColorA  + fresnel + float4(AdditionalLightcolor,1)+ clamp(_MainLightColor ,0.0,0);
                     return sdf  * ColMaintex * _ColorA   + float4(AdditionalLightcolor,1)+ clamp(_MainLightColor ,0.0,0);
                    
                }
            }
            ENDHLSL
        }
        Pass
        {
            
            Cull Front
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Assets/UnrealToUnityShaderLibrary/UnrealToUnityLibrary.hlsl"
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
               float4 VertexColor:COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal:NORMAL;
                float3 WorldPos:TEXCOORD1;
                float4 VertexColor:COLOR;
            };
            CBUFFER_START(setting)
            float _Outline;
            CBUFFER_END
            v2f vert(appdata input)
            {       
                v2f o;
                if(distance(_WorldSpaceCameraPos,input.vertex) <= 1)
                {
                    float4 pos = TransformObjectToHClip(input.vertex);
                    float3 viewNormal = mul((float3x3)UNITY_MATRIX_IT_MV, input.normal.xyz);
                    float3 ndcNormal = normalize(TransformWViewToHClip(viewNormal.xyz)) * pos.w;//将法线变换到NDC空间
                    float4 nearUpperRight = mul(unity_CameraInvProjection, float4(1, 1, UNITY_NEAR_CLIP_VALUE, _ProjectionParams.y));//将近裁剪面右上角的位置的顶点变换到观察空间
                    float aspect = abs(nearUpperRight.y / nearUpperRight.x);//求得屏幕宽高比
                    ndcNormal.x *= aspect;
                    pos.xy += 0.01 * .5 * ndcNormal.xy * 1;//顶点色a通道控制粗细
                    o.vertex = pos;
                    o.VertexColor = input.VertexColor.rgba;
                    return o;
                    
                }
                else
                {
                     float3 result;
                    GetOutline(input.vertex,input.normal,_Outline,result);
                    o.vertex = TransformObjectToHClip(float4(result,1));
                    return  o;
                }

                // float3 result;
                // GetOutline(input.vertex,input.normal,_Outline,result);
                // o.vertex = TransformObjectToHClip(float4(result,1));
                // return  o;

            }
            half4 frag(v2f i):SV_TARGET
            {
                return 0;
            }
            ENDHLSL
        }
            Pass
            {
                Tags {"LightMode" = "Depthonly"}
//                ZTest Always
//                HLSLPROGRAM
//                #include "Assets/UnrealToUnityShaderLibrary/UnrealToUnityLibrary.hlsl"
//                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
//                #pragma vertex vert
//                #pragma fragment frag
//                struct  appdata
//                {
//                    float4 positon:POSITION;
//                };
//
//                struct varying
//                {
//                    float4 positon:SV_POSITION;
//                };
//                varying vert(appdata i)
//                {
//                    varying o;
//                    o.positon = TransformObjectToHClip(i.positon);
//                    return o;
//                }
//                float4 frag(varying i):SV_TARGET
//                {
//                    return float4(1,1,1,1);
//                }
//                ENDHLSL
//            }
            }
            Pass
            {
                Tags {"LightMode" = "ShadowCaster"}
            }
            Pass
            {
                Tags {"LightMode" = "DepthNormals"}
            }
    }
}


