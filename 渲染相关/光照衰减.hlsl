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
【月度复盘】每月必填

	本月主要两个方面的内容，一是狩猎的功能，开服限定礼包功能和累充7日领奖功能，这两个功能都到了只差UI和特效的阶段；

二是URP方面的学习，主要阅读源码来了解URP的工作流程，自己实现了一个ScriptableRendererFeature来熟悉URP的工作流程，URP是默认不支持多pass的，ScriptableRendererFeature可以用来实现多pass的效果，当然也可以通过修改源码的方式来支持多pass.期间学习了URP的相关的其他东西，URP通过SRPBatch在使用了很多相同的shader Varian的材质的场景中加速渲染。URP着色器是shaderGraph或hlsl实现的，通过实现一些简单的效果学习了部分shaderGraph知识。

	在实现开服限定功能时，由于前后端都不很熟悉，导致公告的实现前后端统一不了，之后找秋生沟通解决了。在URP的学习上，由于现在可找到的学习资料有限，主要自己阅读源码，在外网找了catlike的一部分教程，自己对照者看了一部分。

	这个月主要熟悉了URP的一部分，这段时间试着去看看它内部的实现的shader,内部有两个套方法，一套是基于BlinnPhong一套是基于PBR的BlinnPhong的之前看shader入门精要的时候学习过，看起来相对简单一点；PBR看起来就有一点困难，下个月主要看这部分的东西，还有全局光照GI和bakeGI相关的东西。