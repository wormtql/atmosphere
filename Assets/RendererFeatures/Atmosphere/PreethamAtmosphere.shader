Shader "Custom/Hidden/PreethamAtmosphere"
{
    Properties
    {
        [HideInInspector] _MainLightDirection("Main Light Direction", Vector) = (0, -1, 0)
        [HideInInspector] _AtmosphereParams("Atmospheric Params", Vector) = (2, 0, 0, 0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            HLSLPROGRAM

            #pragma vertex PreethamAtmospherePassVertex
            #pragma fragment PreethamAtmospherePassFragment
            #pragma enable_d3d11_debug_symbols

            #include "PreethamAtmosphere.hlsl"
            
            ENDHLSL
        }
    }
}
