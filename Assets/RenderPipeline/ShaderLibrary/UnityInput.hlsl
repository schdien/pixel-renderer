#ifndef CUSTOM_UNITY_INPUT_INCLUDED
#define CUSTOM_UNITY_INPUT_INCLUDED

cbuffer UnityPerDraw {
	float4x4 unity_ObjectToWorld;
	float4x4 unity_WorldToObject;
	float4 unity_LODFade;
	real4 unity_WorldTransformParams;
	//per object light:
	float4 unity_LightData;
	float4 unity_LightIndices[2];
};
cbuffer LightProperties {
	int _DirLightCnt;
	float4 _DirLightColors[4];
	float4 _DirLightDirs[4];
};
float4x4 unity_MatrixVP;
float4x4 unity_MatrixV;
float4x4 unity_MatrixInvV;
float4x4 glstate_matrix_projection;

float4x4 unity_PrevObjectToWorld;
float4x4 unity_PrevWorldToObject;

#endif