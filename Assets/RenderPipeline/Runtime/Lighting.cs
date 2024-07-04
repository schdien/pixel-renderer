using UnityEngine;
using Unity.Collections;
using UnityEngine.Rendering;

public static partial class ShaderProperties
{
    public static int dirLightCntId = Shader.PropertyToID("_DirLightCnt");
    public static int dirLightColorsId = Shader.PropertyToID("_DirLightColors");
    public static int dirLightDirsId = Shader.PropertyToID("_DirLightDirs");
}
public partial class PixelRenderPipeline
{
    static public void SetupShaderLightingParams(ref CullingResults cullingResults,int maxDirLightCnt)
    {
        Vector4[] dirLightColors = new Vector4[maxDirLightCnt];
        Vector4[] dirLightDirs = new Vector4[maxDirLightCnt];
        var visibleLights = cullingResults.visibleLights;
        int visibleLightCnt = visibleLights.Length;

        int dirLightCnt = 0;
        for (int i =0; i < visibleLightCnt; i++)
        {
            switch (visibleLights[i].lightType) {
                case LightType.Directional:
                    dirLightColors[dirLightCnt] = visibleLights[i].finalColor;
                    dirLightDirs[dirLightCnt] = -visibleLights[i].localToWorldMatrix.GetColumn(2);
                    dirLightCnt++;
                    break;
                default:
                    break;
            }
        }
        Shader.SetGlobalInt(ShaderProperties.dirLightCntId, Mathf.Min(dirLightCnt, maxDirLightCnt));
        Shader.SetGlobalVectorArray(ShaderProperties.dirLightColorsId, dirLightColors);
        Shader.SetGlobalVectorArray(ShaderProperties.dirLightDirsId, dirLightDirs);
    }
}
