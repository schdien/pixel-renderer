Shader "Pixel Renderer/PointLight"
{
    Properties
    {
        _Color("Color", COLOR) = (1,1,1,1)
        _Intensity("Intensity", Float) = 1
        _Range("Range", Float) = 1
    }
        SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" "LightMode" = "PixelUnlit"}

        Pass
        {
            Blend One One
            Cull Back
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            cbuffer DepthNormalProperties {
                sampler2D _NormalTex;
                sampler2D _DepthTex;
            };

            #define PI 3.1415926

            struct AppData
            {
                float4 posOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct VertData
            {
                float2 uv : TEXCOORD0;
                float4 posCS : SV_POSITION;
                float4 posSS : TEXCOORD1;
            };

            float4 _Color;
            float _Intensity;
            float _Range;


            VertData vert(AppData v)
            {
                VertData o; 
                o.posCS = UnityObjectToClipPos(v.posOS);
                o.posSS = ComputeScreenPos(o.posCS);
                return o;
            }

            float4 GetWorldPositionFromDepthValue(float2 uv, float depth) //通过深度图倒退世界坐标值
            {
                float camPosZ = _ProjectionParams.y + (_ProjectionParams.z - _ProjectionParams.y) * depth;

                float height = 2 * camPosZ / unity_CameraProjection._m11;
                float width = _ScreenParams.x / _ScreenParams.y * height;

                float camPosX = width * uv.x - width / 2;
                float camPosY = height * uv.y - height / 2;
                float4 camPos = float4(camPosX, camPosY, camPosZ, 1.0);
                return mul(unity_CameraToWorld, camPos);
            }

            float PointLightAtten(float d, float intensity) {
                return min(intensity / (d * d), 5);
            }
            float NormalDistribution(float x, float intensity, float range) //正态分布
            {
                return ((1 / sqrt(2) * PI) * exp(-pow(x * (1 / range), 2) / 2)) * intensity;
            }

            fixed4 frag(VertData i) : SV_Target
            {
                float2 posSS = i.posSS.xy / i.posSS.w;

                float depth = tex2D(_DepthTex, posSS);//++
                float linearDepth = Linear01Depth(depth);
                float3 normalWS = tex2D(_NormalTex, posSS);

                float3 scenePosWS = GetWorldPositionFromDepthValue(posSS, linearDepth).xyz; //获取本体外世界坐标

                float4x4 m = UNITY_MATRIX_M;
                float3 objZeroWS = float3(m[0].w, m[1].w, m[2].w); //获取模型原点的世界位置
                float distance = length(scenePosWS - objZeroWS); //算出世界坐标与模型原点的距离
                float atten = PointLightAtten(distance, _Intensity);
                float4 col = _Color * atten;
                float3 lightDir = normalize(objZeroWS - scenePosWS);//++
                col.rgb = max(col.rgb * dot(normalWS, lightDir), 0);
                return col;
            }
            ENDHLSL
        }
    }
  

}
