#ifndef CUSTOM_DEPTH_PASS_INCLUDED
#define CUSTOM_DEPTH_PASS_INCLUDED

#include "Common.hlsl"


struct AppData {
	float3 posOS : POSITION;
	float3 normalOS: NORMAL;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct VertData {
	float4 posCS : SV_POSITION;
	float3 normalOS: VAR_NORMAL_OS;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

VertData DepthNormalsVert(AppData input) {
	VertData output;
	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_TRANSFER_INSTANCE_ID(input, output);
	output.posCS = TransformObjectToHClip(input.posOS);
	output.normalOS = input.normalOS;
	return output;
}

float4 DepthNormalsFrag(VertData input) : SV_TARGET {
	UNITY_SETUP_INSTANCE_ID(input);
	float3 normalWS = TransformObjectToWorldNormal(input.normalOS,true);
	//float depth = -mul(UNITY_MATRIX_M,mul(UNITY_MATRIX_V, input.posCS)).z;
	return float4(normalWS, 0);
}

#endif