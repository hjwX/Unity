//已知光照的强度与到光源的平方成反比
//计算光照衰减的平滑因子使得光照在range出的强度为0
if (lightData.lightType != LightType.Directional) 
{
    float lightRangeSqr = lightData.range * lightData.range;
    float fadeStartDistanceSqr = 0.8f * 0.8f * lightRangeSqr;
    float fadeRangeSqr = (fadeStartDistanceSqr - lightRangeSqr);
    float oneOverFadeRangeSqr = 1.0f/fadeRangeSqr;
    float lightRangeSqrOverFadeRangeSqr = -lightRangeSqr / fadeRangeSqr;
    float oneOverLightRangeSqr = 1.0f/MathF.Max(0.0001f, lightRangeSqr);

    lightAttenuation.x = Application.isMobilePlatform || FileSystemInfo.graphicsDeviceType == GraphicsDeviceType.Switch ? oneOverFadeRangeSqr : oneOverLightRangeSqr;
    lightAttenuation.y = lightRangeSqrOverFadeRangeSqr;
}

shader中的实现：
float DistanceAttenuation(float distanceSqr, half2 distanceAttenuation)
{
    float lightAtten = rcp(distanceSqr);

    #if SHADER_HINT_NICE_QUALITY
        half factor = distanceSqr * distanceAttenuation.x;
        half smoothFactor = saturate(1.0h - factor * factor);
        smoothFactor = smoothFactor * smoothFactor;
    #else
        half smoothFactor = saturate(distanceSqr * distanceAttenuation.x + distanceAttenuation.y);
    #endif

    return lightAtten * smoothFactor;
}