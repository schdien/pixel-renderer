Shader "Pixel Renderer/Lit"
{
    Properties
    {
		_Albedo("Albedo",Color) = (0.5, 0.5, 0.5, 1.0)
        //_BaseTex("Texture",2D) = "White" {}
        _Cutoff("Alpha Cutoff",Range(0.0,1.0)) = 0.0
        
        [Toggle(_CLIPPING)] _Clipping("Alpha Clipping", float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend", Float) = 0
        [Enum(Off,0,On,1)] _ZWrite("Z Write", Float) = 1
    }
    SubShader
    {
        Pass
        {
            Tags { "LightMode" = "PixelLit" }
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]

            HLSLPROGRAM

            #pragma shader_feature _CLIPPING
            #pragma multi_compile_instancing
            #pragma vertex LitVert
            #pragma fragment LitFrag

			#include "Assets/RenderPipeline/ShaderLibrary/Common.hlsl"
			#include "Assets/RenderPipeline/ShaderLibrary/Light.hlsl"

			//TEXTURE2D(_BaseTex);
			//SAMPLER(sampler_BaseTex);

			UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
				UNITY_DEFINE_INSTANCED_PROP(float4, _Albedo)
				UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)
				//UNITY_DEFINE_INSTANCED_PROP(float4, _BaseTex_ST)
			UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

			struct AppData {
				float3 posOS: POSITION;
				float3 normalOS: NORMAL;
				//float2 TexCoord: TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertData {
				float4 posCS: SV_POSITION;
				float3 posWS: VAR_POS_WS;
				float3 normalWS: VAR_NORMAL_WS;
				//float2 BaseUV: VAR_BASE_UV;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			VertData LitVert(AppData i) {
				VertData o;
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_TRANSFER_INSTANCE_ID(i, o);
				o.posWS = TransformObjectToWorld(i.posOS);
				o.posCS = TransformWorldToHClip(o.posWS);
				o.normalWS = TransformObjectToWorldNormal(i.normalOS,true);
				//float4 BaseTex_ST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseTex_ST);
				//o.BaseUV = i.TexCoord * BaseTex_ST.xy + BaseTex_ST.zw;
				return o;
			}
			float4 LitFrag(VertData i) :SV_TARGET{
				UNITY_SETUP_INSTANCE_ID(i);
				//float4 SampledTex = SAMPLE_TEXTURE2D(_BaseTex, sampler_BaseTex, i.BaseUV);
				float4 albedo = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Albedo);
				//albedo *= SampledTex;
			#ifdef _CLIPPING
				clip(albedo.a - UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff));
			#endif
				int lightCnt = GetDirLightCnt();
				DirLight light;
				float4 diffuse;
				
				for (int index = 0; index < lightCnt; index++) {
					light = GetDirLight(index);
					diffuse += dot(i.normalWS, light.dir) * light.color * albedo;
				}
				return diffuse;
				
			}
            ENDHLSL
        }

		Pass
		{
			Tags{"LightMode" = "ShadowCaster"}
			
			ColorMask 0
			HLSLPROGRAM
			#pragma shader_feature _CLIPPING
			#pragma multi_compile_instancing
			#pragma vertex ShadowCasterVert
			#pragma fragment ShadowCasterFrag
			#include "Assets/RenderPipeline/ShaderLibrary/ShadowCasterPass.hlsl"
			ENDHLSL
		}
		Pass
		{
			Tags{"LightMode" = "DepthNormal"}

			HLSLPROGRAM
			#pragma multi_compile_instancing
			#pragma vertex DepthNormalsVert
			#pragma fragment DepthNormalsFrag
			#include "Assets/RenderPipeline/ShaderLibrary/DepthNormalsPass.hlsl"
			ENDHLSL
		}
    }
}
