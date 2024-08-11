using JetBrains.Annotations;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace RendererFeatures.Atmosphere
{
    public class PreethamAtmospherePass: ScriptableRenderPass
    {
        [CanBeNull] private Material _atmosphereMaterial;
        [CanBeNull] private Light _mainLight;

        private void CreateMaterialIfNotSet()
        {
            if (_atmosphereMaterial == null)
            {
                _atmosphereMaterial = Resources.Load<Material>("Atmosphere/PreethamAtmosphere");
            }
        }
        
        public PreethamAtmospherePass()
        {
            CreateMaterialIfNotSet();
            
            // _mainLight = 
        }
        
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var cmd = CommandBufferPool.Get("PreethamAtmosphere");
            cmd.Clear();

            cmd.DrawProcedural(Matrix4x4.identity, _atmosphereMaterial, 0, MeshTopology.Triangles, 3);
            
            context.ExecuteCommandBuffer(cmd);

            CommandBufferPool.Release(cmd);
        }
    }
}
