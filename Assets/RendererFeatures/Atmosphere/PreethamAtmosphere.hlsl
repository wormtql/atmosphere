#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

struct Attributes
{
    uint id: SV_VertexID;
};

struct Varyings
{
    float4 positionCS: SV_POSITION;
    float3 viewDir: TEXCOORD0;
};

Varyings PreethamAtmospherePassVertex(Attributes input)
{
    Varyings output;

    int x = input.id & 1;
    int y = input.id >> 1;

    float xx = x * 4 - 1;
    float yy = y * 4 - 1;
    
    output.positionCS = float4(xx, yy, 0.0001, 1);

    float h2 = 1 / UNITY_MATRIX_P._m11;
    float w2 = 1 / UNITY_MATRIX_P._m00;

    #if UNITY_UV_STARTS_AT_TOP
    float3 dir = float3(xx * w2, -yy * h2, 1);
    #else
    float3 dir = float3(xx * w2, yy * h2, 1);
    #endif
    output.viewDir = normalize(dir);

    return output;
}

#define GeneratePerezFormula(Name, A1, A2, B1, B2, C1, C2, D1, D2, E1, E2) float Name(float cos_theta, float gamma, float cos_gamma, float turbidity) { \
    float A = A1 * turbidity + A2; \
    float B = B1 * turbidity + B2; \
    float C = C1 * turbidity + C2; \
    float D = D1 * turbidity + D2; \
    float E = E1 * turbidity + E2; \
    float temp = 1 + A * exp(B / cos_theta); \
    float temp2 = 1 + C * exp(D * gamma) + E * cos_gamma * cos_gamma; \
    return temp * temp2; \
}

// Y
GeneratePerezFormula(PerezLuminance, 0.1787, -1.4630, -0.3554, 0.4275, -0.0227, 5.3251, 0.1206, -2.5771, -0.0670, 0.3703)
// x
GeneratePerezFormula(PerezChromeX, -0.0193, -0.2592, -0.0665, 0.0008, -0.0004, 0.02125, -0.0641, -0.8989, -0.0033, 0.0452)
// y
GeneratePerezFormula(PerezChromeY, -0.0167, -0.2608, -0.0950, 0.0092, -0.0079, 0.2102, -0.0441, -1.6537, -0.0109, 0.0529)

float ZenithLuminance(float turbidity, float theta_sun)
{
    float chi = (4.0 / 9 - turbidity * (1.0 / 120)) * (PI - 2 * theta_sun);
    return (4.0453 * turbidity - 4.9710) * tan(chi) - 0.2155 * turbidity + 2.4192;
}

float ZenithChromeX(float turbidity, float theta_sun)
{
    float3 T = float3(turbidity * turbidity, turbidity, 1);
    float t2 = theta_sun * theta_sun;
    float4 Theta = float4(t2 * theta_sun, t2, theta_sun, 1);

    float3x4 mat = float3x4(
        0.0017, -0.0037, 0.0021, 0,
        -0.0290, 0.0638, -0.0320, 0.0039,
        0.1169, -0.2120, 0.0605, 0.2589
    );
    return mul(mul(T, mat), Theta);
}

float ZenithChromeY(float turbidity, float theta_sun)
{
    float3 T = float3(turbidity * turbidity, turbidity, 1);
    float t2 = theta_sun * theta_sun;
    float4 Theta = float4(t2 * theta_sun, t2, theta_sun, 1);

    float3x4 mat = float3x4(
        0.0028, -0.0061, 0.0032, 0,
        -0.0421, 0.0897, -0.0415, 0.0052,
        0.1535, -0.2676, 0.0667, 0.2669
    );
    return mul(mul(T, mat), Theta);
}

float3 Convert_xYy_to_XYZ(float3 xYy)
{
    float x = xYy.x;
    float Y = xYy.y;
    float y = xYy.z;
    float X = Y / y * x;
    float Z = Y / y * (1 - x - y);

    return float3(X, Y, Z);
}

float3 Convert_XYZ_to_sRGB(float3 XYZ)
{
    float3x3 mat = float3x3(
        3.2404542, -1.5371385, -0.4985314,
        -0.9692660, 1.8760108, 0.0415560,
        0.0556434, -0.2040259, 1.0572252
    );
    return mul(mat, XYZ);
}

float4 _AtmosphereParams;

#define _Turbidity _AtmosphereParams.x

float4 PreethamAtmospherePassFragment(Varyings input): SV_Target
{
    float2 screenUV = input.positionCS.xy / _ScaledScreenParams.xy;
    float3 positionWS = ComputeWorldSpacePosition(screenUV, 0.999, UNITY_MATRIX_I_VP);
    float3 dir = normalize(positionWS - GetCameraPositionWS());
    
    float3 lightDir = _MainLightPosition.xyz;

    if (dir.y < 0)
    {
        return float4(0, 0, 0, 1);
    }
    
    float cos_theta_sun = lightDir.y;
    float theta_sun = acos(cos_theta_sun);
    float cos_theta = dir.y;
    float cos_gamma = dot(dir, lightDir);
    float gamma = acos(cos_gamma);

    float zenith_luminance = ZenithLuminance(_Turbidity, theta_sun);
    float luminance = zenith_luminance * PerezLuminance(cos_theta, gamma, cos_gamma, _Turbidity) / PerezLuminance(1, theta_sun, cos_theta_sun, _Turbidity);
    // luminance = luminance / (1 + luminance);

    float zenith_chrome_x = ZenithChromeX(_Turbidity, theta_sun);
    float chrome_x = zenith_chrome_x * PerezChromeX(cos_theta, gamma, cos_gamma, _Turbidity) / PerezChromeX(1, theta_sun, cos_theta_sun, _Turbidity);

    float zenith_chrome_y = ZenithChromeY(_Turbidity, theta_sun);
    float chrome_y = zenith_chrome_y * PerezChromeY(cos_theta, gamma, cos_gamma, _Turbidity) / PerezChromeY(1, theta_sun, cos_theta_sun, _Turbidity);

    float3 XYZ = Convert_xYy_to_XYZ(float3(chrome_x, luminance, chrome_y));
    float3 rgb = Convert_XYZ_to_sRGB(XYZ);
    rgb *= 0.01;
    // rgb = rgb / (1 + rgb);

    return float4(rgb , 1);
}
