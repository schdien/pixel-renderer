#ifndef CUSTOM_LIGHT_INCLUDED
#define CUSTOM_LIGHT_INCLUDED

#include "UnityInput.hlsl"

struct DirLight {
	float4 color;
	float3 dir;
};
int GetDirLightCnt() {
	return _DirLightCnt;
}

DirLight GetDirLight(int i) {
	DirLight light;
	light.color = _DirLightColors[i];
	light.dir = _DirLightDirs[i].xyz;
	return light;
}

/*
float3 CalculateLighting(Light light, float3 posWS, float3 normal) {
	float3 lightVec = light.posOrDir.xyz - posWS * light.posOrDir.w; //w of Directional Light is 0, others are 1
	float attenRatio = dot(lightVec, lightVec) * light.atten.x;
	attenRatio = saturate(1.0 - attenRatio * attenRatio);
	attenRatio *= attenRatio;
	float distanceSqr = max(dot(lightVec, lightVec), 0.00001);
	float diffuse = saturate(dot(normal, normalized(lightVec)));
	diffuse *= attenRatio / distanceSqr;
	return diffuse * light.color;
}
*/
#endif