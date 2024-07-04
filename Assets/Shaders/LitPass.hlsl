#ifndef CUSTOM_LIT_PASS_INCLUDED
#define CUSTOM_LIT_PASS_INCLUDED

#include "Assets/ShaderLibrary/Common.hlsl"
#include "Assets/ShaderLibrary/Surface.hlsl"
#include "Assets/ShaderLibrary/Lighting.hlsl"

TEXTURE2D(_BaseTex);
SAMPLER(sampler_BaseTex);

UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
	UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
	UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)
	UNITY_DEFINE_INSTANCED_PROP(float4, _BaseTex_ST)
UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

struct AppData {
	float3 positionOS: POSITION;
	float3 normalOS: NORMAL;
	float2 TexCoord: TEXCOORD0;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct VertData {
	float4 positionCS: SV_POSITION;
	float3 normalWS: VAR_NORMAL;
	float2 BaseUV: VAR_BASE_UV;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

VertData LitPassVertex(AppData input) {
	VertData output;
	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_TRANSFER_INSTANCE_ID(input, output);
	output.positionCS = TransformObjectToHClip(input.positionOS);
	output.normalWS = TransformObjectToWorldNormal(input.normalOS);
	float4 BaseTex_ST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseTex_ST);
	output.BaseUV = input.TexCoord * BaseTex_ST.xy + BaseTex_ST.zw;
	return output;
}
float4 LitPassFragment(VertData input) :SV_TARGET{
	UNITY_SETUP_INSTANCE_ID(input);
	float4 SampledTex = SAMPLE_TEXTURE2D(_BaseTex, sampler_BaseTex, input.BaseUV);
	float4 baseColor = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor);
	float4 color = baseColor * SampledTex;
#ifdef _CLIPPING
	clip(color.a - UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff));
#endif
	Surface surface;
	surface.normal = input.normalWS;
	surface.color = color.rgb;
	surface.alpha = color.a;
	color = float4(GetLighting(input.normalWS, color.rgb), color.a);
	return color;
}
#endif