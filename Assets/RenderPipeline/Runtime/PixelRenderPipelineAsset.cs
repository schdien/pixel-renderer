using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using Unity.Collections;

[CreateAssetMenu(menuName = "Rendering/PixelRenderPipelineAsset")]
public class PixelRenderPipelineAsset : RenderPipelineAsset
{
    public ShadowSettings shadowSettings = default;
    public OptimizeSettings optimizeSettings = default;
    public Material screenSpaceShadowMat = null;
    protected override RenderPipeline CreatePipeline()
    {
            return new PixelRenderPipeline(optimizeSettings, shadowSettings, screenSpaceShadowMat);
    }
}

public partial class PixelRenderPipeline : RenderPipeline
{
    Material screenSpaceShadowMat;
    ShadowSettings shadowSettings;
    OptimizeSettings optimizeSettings;

    ShaderTagId[] shaderTags = new ShaderTagId[] {new ShaderTagId("PixelLit"),new ShaderTagId("PixelUnlit") };

    public PixelRenderPipeline(OptimizeSettings optimizeSettings, ShadowSettings shadowSettings, Material screenSpaceShadowMat)
    {
        this.shadowSettings = shadowSettings;
        this.optimizeSettings = optimizeSettings;
        this.screenSpaceShadowMat = screenSpaceShadowMat;
        GraphicsSettings.lightsUseLinearIntensity = true;
        GraphicsSettings.useScriptableRenderPipelineBatching = optimizeSettings.useSRPBatching;
        GraphicsSettings.lightsUseLinearIntensity = true;
    }

    protected override void Render(ScriptableRenderContext context, Camera[] cameras)
    {
        foreach (var camera in cameras)
        {
            RenderPerCamera(context, camera);
        } 
    }

    private void RenderPerCamera(ScriptableRenderContext context, Camera camera)
    {
        //Setup Camera Properties
        context.SetupCameraProperties(camera);

        //clear previous frame
        CommandBuffer cmd = new CommandBuffer() { name = "camera"};
        cmd.ClearRenderTarget(true, true, Color.clear);
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();

        cmd.BeginSample("camera");
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();

        //cull scene
        camera.TryGetCullingParameters(out var cullingParams);
        cullingParams.shadowDistance = Mathf.Min(shadowSettings.maxDistance, camera.farClipPlane);
        var cullingResults = context.Cull(ref cullingParams);

        //Pass light data to shaders
        SetupShaderLightingParams(ref cullingResults,2);


        RenderDepthNormal(context, cullingResults, camera);
        //render shadow map
        
        RenderShadows(context, cullingResults, shadowSettings, 2);

        //RenderDirLightScreenSpaceShadowTex(context, screenSpaceShadowMat);

        //reset camera properties(render target)
        context.SetupCameraProperties(camera);

        //initial draw setting and shader tags
        var drawSettings = new DrawingSettings() { 
            enableInstancing = optimizeSettings.useGPUInstancing, 
            enableDynamicBatching = optimizeSettings.useDynamicBatching,  
        };
        for (int i = 0; i < shaderTags.Length; i++)
        {
            drawSettings.SetShaderPassName(i, shaderTags[i]);
        }
        //set and draw opaque
        var sortingSetting = new SortingSettings(camera) { criteria = SortingCriteria.CommonOpaque };
        drawSettings.sortingSettings = sortingSetting;
        var filterSetting = new FilteringSettings(RenderQueueRange.opaque);
        context.DrawRenderers(cullingResults, ref drawSettings, ref filterSetting);
        
        //draw skybox
        context.DrawSkybox(camera);

        //set and draw transparent
        sortingSetting.criteria = SortingCriteria.CommonTransparent;
        drawSettings.sortingSettings = sortingSetting;
        filterSetting.renderQueueRange = RenderQueueRange.transparent;
        context.DrawRenderers(cullingResults, ref drawSettings, ref filterSetting);

        
        cmd.EndSample("camera");
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();

        context.Submit();
    }
    //void AddCommandToContext(ScriptableRenderContext context, CommandBuffer cmd)

}
