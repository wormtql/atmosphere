using System.Collections;
using System.Collections.Generic;
using JetBrains.Annotations;
using UnityEngine;
using UnityEngine.Rendering.Universal;

namespace RendererFeatures.Atmosphere
{
    public class PreethamAtmosphereRendererFeature : ScriptableRendererFeature
    {
        [CanBeNull] private PreethamAtmospherePass _preethamAtmospherePass;
        
        public override void Create()
        {
            _preethamAtmospherePass = new PreethamAtmospherePass();
            _preethamAtmospherePass.renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            var cameraType = renderingData.cameraData.cameraType;

            if (cameraType == CameraType.Game || cameraType == CameraType.SceneView)
            {
                renderer.EnqueuePass(_preethamAtmospherePass);
            }
        }
    }
}
