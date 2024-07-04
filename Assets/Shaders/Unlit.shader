Shader "Pixel Renderer/Unlit"
{
    Properties
    {
        _BaseColor("Color",Color) = (1.0, 1.0, 1.0, 1.0)
        _BaseTex("Texture",2D) = "White" {}
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
                Tags { "LightMode" = "PixelUnlit" }
                Blend[_SrcBlend][_DstBlend]
                ZWrite[_ZWrite]

                HLSLPROGRAM

                #pragma shader_feature _CLIPPING
                #pragma multi_compile_instancing
                #pragma vertex UnlitPassVertex
                #pragma fragment UnlitPassFragment

                #include "Assets/RenderPipeline/ShaderLibrary/Common.hlsl"

                TEXTURE2D(_BaseTex);
                SAMPLER(sampler_BaseTex);

                UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                    UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
                    UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)
                    UNITY_DEFINE_INSTANCED_PROP(float4, _BaseTex_ST)
                UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

                struct AppData {
                    float3 positionOS: POSITION;
                    float2 TexCoord: TEXCOORD0;
                    UNITY_VERTEX_INPUT_INSTANCE_ID
                };

                struct VertData {
                    float4 positionCS: SV_POSITION;
                    float2 BaseUV: VAR_BASE_UV;
                    UNITY_VERTEX_INPUT_INSTANCE_ID
                };

                VertData UnlitPassVertex(AppData input) {
                    VertData output;
                    UNITY_SETUP_INSTANCE_ID(input);
                    UNITY_TRANSFER_INSTANCE_ID(input, output);
                    output.positionCS = TransformObjectToHClip(input.positionOS);
                    float4 BaseTex_ST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseTex_ST);
                    output.BaseUV = input.TexCoord * BaseTex_ST.xy + BaseTex_ST.zw;
                    return output;
                }
                float4 UnlitPassFragment(VertData input) :SV_TARGET{
                    UNITY_SETUP_INSTANCE_ID(input);
                    float4 SampledTex = SAMPLE_TEXTURE2D(_BaseTex, sampler_BaseTex, input.BaseUV);
                    float4 baseColor = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor);
                    float4 color = baseColor * SampledTex;
                #ifdef _CLIPPING
                    clip(color.a - UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff));
                #endif
                    return baseColor;
                }
                ENDHLSL
            }
        }
}