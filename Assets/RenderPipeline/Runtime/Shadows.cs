using UnityEngine;
using UnityEngine.Rendering;
using System.Collections.Generic;

public static partial class ShaderProperties
{
    public static int dirShadowAtlasId = Shader.PropertyToID("_DirShadowAtlas");
    public static int dirShadowMatricesId = Shader.PropertyToID("_DirShadowMatricesId");

    public static int depthTexId = Shader.PropertyToID("_DepthTex");
    public static int normalTexId = Shader.PropertyToID("_NormalTex");

    public static int screenSpaceShadowTexId = Shader.PropertyToID("_ScreenSpaceShadowTex");
}
public partial class PixelRenderPipeline
{
    void RenderDepthNormal(ScriptableRenderContext context, CullingResults cullingResults, Camera camera)
    {
        var cmd = new CommandBuffer() { name = "DepthNormal" };
        cmd.GetTemporaryRT(ShaderProperties.depthTexId, camera.pixelWidth, camera.pixelHeight, 24, FilterMode.Point, RenderTextureFormat.Depth);
        cmd.GetTemporaryRT(ShaderProperties.normalTexId, camera.pixelWidth, camera.pixelHeight, 0);
        cmd.SetRenderTarget(ShaderProperties.normalTexId, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store,
            ShaderProperties.depthTexId, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
        cmd.ClearRenderTarget(true, true, Color.clear);
        cmd.BeginSample("DepthNormal");
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();

        var drawSettings = new DrawingSettings(new ShaderTagId("DepthNormal"), new SortingSettings(camera))
        {
            enableInstancing = optimizeSettings.useGPUInstancing,
            enableDynamicBatching = optimizeSettings.useDynamicBatching,
        };

        //set and draw opaque
        var filterSetting = new FilteringSettings(RenderQueueRange.opaque);
        context.DrawRenderers(cullingResults, ref drawSettings, ref filterSetting);
        cmd.EndSample("DepthNormal");
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
    }
    void RenderShadows(ScriptableRenderContext context, CullingResults cullingResults, ShadowSettings settings, int maxShadowedDirLightCnt)
    {
        //var shadowedDirLights = new ShadowedDirLight[maxShadowedDirLightCnt];
        var visibleLights = cullingResults.visibleLights;

        //setup Shadow render texture
        var cmd = new CommandBuffer() { name = "Shadows" };
        int atlasSize = (int)settings.directional.atlasSize;
        cmd.GetTemporaryRT(ShaderProperties.dirShadowAtlasId, atlasSize, atlasSize, 32, FilterMode.Bilinear, RenderTextureFormat.Shadowmap); //rectangle texture
        cmd.SetRenderTarget(ShaderProperties.dirShadowAtlasId, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
        cmd.ClearRenderTarget(true, false, Color.clear);
        cmd.BeginSample("Shadows");
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();

        List<int> dirLightIndices = new List<int>();
        for (int i = 0; i < visibleLights.Length; i++)
        {
            Light light = visibleLights[i].light; 
            if (dirLightIndices.Count < maxShadowedDirLightCnt &&
                visibleLights[i].lightType == LightType.Directional &&
                light.shadows != LightShadows.None && light.shadowStrength > 0f &&
                cullingResults.GetShadowCasterBounds(i, out Bounds bounds))
            {
                dirLightIndices.Add(i);
            }
        }


        RenderDirShadows(context, cullingResults, atlasSize, dirLightIndices);
        cmd.EndSample("Shadows");
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
    }

    void RenderDirShadows(ScriptableRenderContext context, CullingResults cullingResults,int atlasSize,List<int> dirLightIndices)
    {
        int split = dirLightIndices.Count <= 1 ? 1 : 2;
        int tileSize = atlasSize / split;
        foreach (var dirLightIndex in dirLightIndices)
        {
            var shadowDrawSettings = new ShadowDrawingSettings(cullingResults, dirLightIndex);
            cullingResults.ComputeDirectionalShadowMatricesAndCullingPrimitives(dirLightIndex, 0, 1, Vector3.zero,
                tileSize, 0f, out Matrix4x4 viewMatrix, out Matrix4x4 projMatrix, out ShadowSplitData splitData);
            shadowDrawSettings.splitData = splitData;

            var cmd = new CommandBuffer() { name = "Directional" };

            Vector2 offset = new Vector2(dirLightIndex % split, dirLightIndex / split);
            cmd.SetViewport(new Rect(offset.x * tileSize, offset.y * tileSize, tileSize, tileSize));
            cmd.SetViewProjectionMatrices(viewMatrix, projMatrix);

            cmd.BeginSample("Directional");
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();

            context.DrawShadows(ref shadowDrawSettings);

            cmd.EndSample("Directional");
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            /*
            Shader.SetGlobalMatrix("_WorldToShadow", projMatrix * viewMatrix);
            cmd.GetTemporaryRT(ShaderProperties.screenSpaceShadowTexId, camera.pixelWidth, camera.pixelHeight, 0);
            cmd.Blit(null, ShaderProperties.screenSpaceShadowTexId, mat);
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();*/
        }
    }

    void RenderDirLightScreenSpaceShadowTex(ScriptableRenderContext context, Camera camera, Material mat)
    {
        //Shader.SetGlobalMatrix("_WorldToShadow", projectionMatrix * _lightCamera.worldToCameraMatrix);
        var cmd = new CommandBuffer() { name = "ScreenSpaceShadow" };
        cmd.GetTemporaryRT(ShaderProperties.screenSpaceShadowTexId, camera.pixelWidth, camera.pixelHeight, 0);
        cmd.Blit(null, ShaderProperties.screenSpaceShadowTexId, mat);
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
    }
 
    public void CleanUp(ScriptableRenderContext context)
    {
        var cmd = new CommandBuffer();
        cmd.ReleaseTemporaryRT(ShaderProperties.dirShadowAtlasId);
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
       
    }

}
