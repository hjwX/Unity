using System.Linq.Expressions.Interpreter;
代码设定部分：

    static void InitializeRenderingData(UniversalRenderPipelineAsset settings， ref CameraData cameraData, ref CullingResults cullResults, bool requiresBlitToBackbuffer, bool anyPostPreocessingEnabled, out RederingData renderingdata)
    {
        var visibleLights = cullResults.visibleLights;

        int mainLightIndex = GetMainLightIndex(settings, visibleLights);

        bool mainLightCastShadows = false;
        bool additionalLightsCastShadows = false;

        //cameraData.maxShadowDistance <= 0 肯定是没有阴影可以render的
        if (cameraData.maxShadowDistance > 0.0f) 
        {
            mainLightCastShadows = mainLightIndex != -1 
                                && visibleLights[mainLightIndex].light != null
                                && visibleLights[mainLightIndex].light.shadows != LightShadows.None;

            //只有当额外的光 是像素渲染时 才有可能渲染阴影
            if (settings.additionalLightsRenderingMode == LightRenderingMode.PerPixel) 
            {
                for (int i = 0; i < visibleLight.Length; i++) 
                {
                    if (i == mainLightIndex)
                        continue;
                    Light light = visibleLights[i].light;
                    //URP现在只有spot类型的光 才额外的渲染阴影
                    if (visibleLights[i].lightType == LightType.Spot && light != null && LightLambda.shadows != LightShadows.None) 
                    {
                        additionalLightsCastShadows = true;
                        break;
                    }
                }
            }
        }

        renderingData.cullResults = cullResults;
        renderingData.cameraData = cameraData;

        InitializeLightData(settings, visibleLights, mainLightIndex, out renderingData.lightData);

    }


    CullingResults:可以获取到相机剪裁后可以获得的lights, object, reflectivity probe;

    //返回了最亮的方向光
    //只能是方向光  最亮
    static int GetMainLightIndex(UniversalRenderPipelineAsset setting, NativeArray<VisibleLight> visibleLights)
    {
        int totalVisibleLights = visibleLights.Length;

        if (totalVisibleLights == 0 || settings.mainLightRenderingMode != LightRenderingMode.PerPixel) 
            return -1;

        //RenderSettings.sun可以在Lighting Settings面板中 Environment的sun source中设置
        //如果没有设置 会默认取默认当前最亮的方向光， 没有方向光则为空
        Light sunLight = RenderSettings.sun;
        int brightestDirectionLightIndex = -1;
        float brightestLightIntensity = 0.0f;

        for (int i= 0; i < totalVisibleLights; i++)
        {
            VisibleLight currVisibleLight = visibleLights[i];
            Light currLight = currVisibleLight.light;
            if (currLight == null)
                break;
            
            if (currLight == sunLight)
                return i;
            
            if (currVisibleLight.lightType = LightType.Directional && currLight.intensity > brightestLightIntensity) 
            {
                brightestLightIntensity = currLight.Intensity;
                brightestDirectionLightIndex = i;
            }
        }
        return brightestDirectionLightIndex;
    }

    static void InitializeLightData(UniversalRenderPipelineAsset settings, NativeArray<VisibleLight> visibleLights, int mainLightIndex, out LightData lightData)
    {
        int maxPerObjectAdditionalLight = UniversalRenderPipeline.maxPerObjectLights;
        int maxVisibleAdditionLights = UniversalRenderPipeline.maxVisibleAdditionLights;

        lightData.mainLightIndex = mainLightIndex;

        if (settings.additionalLightsRenderingMode != LightRenderingMode.Disabled) 
        {

        }


    }































/**计算正常的表面的颜色的透明度时，使用BaseMap采样的结果乘与BaseColor这样就得到了表面该处的颜色和透明值
当时当设置了_SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A或者_GLOSSING_FROM_BASE_ALPHA时
BaseMap的Alpha通道值不再代表表面该处的alpha通道值,这个时候直接取BaseColor的alpha值作为该处颜色的透明值
简单来说：
    正常：finalAlpha = BaseMap.Alpha * BaseColor.Alpha;
    有这两个定义之后：finalAlpha = BaseColor.Alpha;
        BaseMap.Alpha有另外的用途
**/

half Alpha(half albedoAlpha, half4 color, half cutoff)
{
    #if !defined(_SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A) && !defined(_GLOSSINESS_FROM_BASE_ALPHA)
        half alpha = albedoAlpha * color.a;
    #else
        half alpha = color.a;
    #endif

    #if defined(_ALPHATEST_ON)
        clip(alpha - cutoff);
    #endif

    return alpha;
}

//简单来说就是 inspector上选择的是Specular则_SPECULAR_SETUP就是true
isSpecularWorkFlow = (WorkflowMode)material.GetFloat("_WorkflowMode") == WorkflowMode.Specular;
CoreUtils.SetKeyword(material, "_SPECULAR_SETUP", isSpecularWorkFlow);

//_METALLICSPECGLOSSMAP判断当前的工作流有没有使用光泽度贴图
hasGlossMap = false
if (isSpecularWorkFlow) 
    hasGlossMap = material.GetTexture("_SpecGlossMap") != null;
else
    hasGlossMap = material.GetTexture("_MetallicGlossMap") != null;
CoreUtils.SetKeyword(material, "_METALLICSPECGLOSSMAP", hasGlossMap);


/**采样金属或者高光贴图
如果使用了贴图采样贴图的颜色值
    如果_BaseMap的Alpha有被使用，则舍弃掉光泽度贴图的Alpha值 finalSmoothness = _Smoothness*albedoAlpha
    如果没有则使用 finalSmoothness = specGloss.a * _Smoothness
没有使用贴图
    specular工作流：使用_Specular.rgb作为颜色的非Alpha部分的值(实际上官方给的_Specular是没有alpha值可以设置的)
    Metallic工作流：使用_Metallic的值作为颜色的RGB部分当时金属工作流时 颜色值由Metallic计算出来

    如果_BaseMap的Alpha有被使用finalSmoothness = _Smoothness*albedoAlpha
    如果没有则使用 此时并没有其他的Smoothness值给到，直接finalSmoothness = _Smoothness
**/

half4 SampleMetallicSpecGloss(float2 uv, half albedoAlpha)
{
    half4 specGloss;

    #ifdef _METALLICSPECGLOSSMAP
        specGloss = SAMPLE_METALLICSPECULAR(uv);
        #ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            specGloss.a = albedoAlpha * _Smoothness;
        #else
            specGloss.a *= _Smoothness;
        #endif
    #else
        #if _SPECULAR_SETUP
            specGloss.rgb = _SpecColor.rgb;
        #else
            specGloss.rgb = _Metallic.rrr;
        #endif
        #ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            specGloss.a = albedoAlpha * _Smoothness;
        #else
            specGloss.a = _Smoothness;
        #endif
    #endif
    return specGloss;
}

//Reflectivity反射率


//表面的粗糙值
PerceptualRoughness = 1 - smoothness
Roughness = PerceptualRoughness * PerceptualRouhness
Roughness^2 = Roughness * Roughness

/**
h = (L + V) /|L + V|
NoH = h * n 
L是光源的方向 
V是该点到眼睛的位置
n是该点的法线方向
a = roughness^2

法线分布函数：D = roughness^2  / PI * (NoH^2 *( roughness^2 - 1) + 1)^2
函数计算出来的是一个数值，代表了表面上有多少的微表面的法线方向是和h的方向是相同的，而当法线的方向和h相同时反射的光线就会直接进入眼睛

几何遮蔽函数：G = n*L/lerp(n*L, 1, k) * n*V/lerp(n*V, 1, k)
其实就是分别计算 光线到该点的遮蔽值 * 光线到视线的遮蔽值
直接光照 k = (a + 1)^2 / 8 间接光照 k = a^2 / 2
计算出来的数值就是 实际反射光线的占比

菲涅尔方程：F=lerp((1 - n*V)^5, 1, F0) (此方程只是一个近似，同样遵循 看起来是对的那就是对的原则)
F0 = mix(vec3(0.04), albedo, metallic)
计算出来反射光线的占比


**/

struct SurfaceData{
    half3 albedo;  //表面的颜色
    half3 specular; //高光的颜色
    half metallic;  //金属度
    half smoothness; //光滑度
    half3 normalTS;  //切线空间下的法线向量
    half3 emission;  //自发光
    half occlusion;  //遮挡
    half alpha;      //alpha
}


inline void InitializeStandardLitSurfaceData(float2 uv, out SurfaceData outSurfaceData)
{
    //对BaseMap采样获取到此处的颜色值和alpha值
    half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));

    //计算此处的alpha值
    outSurfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);

    //获取光泽度参数
    half4 specGloss = SampleMetallicSpecGloss(uv, albedoAlpha.a);

    //表面的颜色值
    outSurfaceData.albedo = albedoAlpha.rgb  * _BaseColor.rgb;

    #if _SPECULAR_SETUP
        outSurfaceData.metallic = 1.0h;
        outSurfaceData.specular = specGloss.rgb;
    #else
        outSurfaceData.metallic = specGloss.r;
        outSurfaceData.specular = half3(0.0h, 0.0h, 0.0h);
    #endif

    outSurfaceData.smoothness = specGloss.a;
    outSurfaceData.normalTS = SampleNormal(uv, Texture2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
    outSurfaceData.occlusion = SampleOcclusion(uv);
    outSurfaceData.emission = SampleEmission(uv, _EmissionColor,rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_Emission));
}

half4 SampleAlbedoAlpha(float2 uv, TEXTURE2D_PARAM(albedoAlphaMap, sampler_albedoAlphaMap))
{
    SAMPLER_TEXTURE2D(albedoAlphaMap, sampler_albedoAlphaMap, uv);
}


struct InputData
{
    float3 positionWS;  //世界坐标
    half3 normalWS;
    half3 viewDirectionWS;
    float4 shadowCoord;
    half fogCoord;
    half3 bakedGI;          //烘焙的全局光照
    half3 vertexLighting;   //逐顶点计算光照的光的颜色
}

//LitForwardPass.hlsl
void InitializeInputData(Varyings input, half3 normalTS, out InputData inputData)
{
    inputData = (inputData)0;
    #if defined(REQUIRE_WORLD_SPACE_POS_INTERPOLATOR)
        inputData.positionWS = input.positionWS;
    #endif

    #ifdef _NORMALMAP
        half3 viewDirWS = half3(input.normalWS.w, input.tangentWS.w, input.bitangentWS.w);
        inputData.normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz));
    #else
        half3 viewDirWS = input.viewDirWS;
        inputData.normalWS = input.normalWS;
    #endif
    inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
    viewDirWS = SafeNormalize(viewDirWS);
    inputData.viewDirectionWS = viewDirws;

    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
        inputData.shadowCoord = input.shadowCoord;
    #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
        inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
    #else
        inputData.shadowCoord = float4(0,0,0,0);
    #endif

    inputData.fogCoord = input.fogFactorAndVertexLight.x;
    inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
    inputData.bakeGI = SAMPLE_GI(input.lightmapUV, input.vertexSH， inputData.normalWS);
}

//half4 color = UniversalFragmentPBR(inputData, surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness, surfaceData.emission, surfaceData.alpha);

half4 UniversalFragmentPBR(InputData inputData, half3 albedo, half metallic, half3 specular, half smoothness, half occlusion, half3 emission, half alpha)
{
    BRDFData brdfData;
    InitializeBRDFData(albedo, metallic, specular, smoothness, alpha, brdfData);
    
    Light mainLight = GetMainLight(inputData.shadowCoord);
    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, half4(0,0,0,0));

    half3 color = GlobalIllumination(brdfData, inputData.bakedGI, occlusion, inputData.normalWS, inputData.viewDirectionWS);
    color += LightingPhysicallyBased(brdfDafa, mainLight, inputData.normalWS, inputData.viewDirectionWS);

    #ifdef _ADDITIONAL_LIGHT
        uint pixelLightCount = GetAdditionalLightCount();
        for (uint lightIndex = 0u; lightIndex < pixelLightCount; lightCount++)
        {
            Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
            color += LightingPhysicallyBased(brdfDafa, light, inputData.normalWS, inputData.viewDirectionWS);
        }
    #endif

    #ifdef _ADDITIONAL_LIGHTS_VERTEX
        color += inputData.vertexLighting * brdfData.diffuse;
    #endif

    //自发光在最后直接机上
    color += emission;
    return half4(color, alpha);
}


InitializeBRDFData(half3 albedo, half metallic, half3 specular, half smoothness, half alpha, out BRDFData outBRDFData)
{
    #ifdef _SPECULAR_SETUP
        half reflectivity = ReflectivitySpecular(specular);
        half oneMinusReflectivity = 1.0 - reflectivity;

        outBRDFData.diffuse = albedo * (half3(1.0h, 1.0h, 1.0h) - specular);
        outBRDFData.specular = specular;
    #else
        half oneMinusReflectivity = OneMinusReflectivityMetallic(metallic);
        half reflectivity = 1.0 - oneMinusReflectivity;

        outBRDFData.diffuse = albedo * oneMinusReflectivity;
        outBRDFData.specular = lerp(kDieletricSpec.rgb, albedo, metallic);
    #endif

    outBRDFData.grazingTerm = saturate(smoothness + reflectivity);
    outBRDFData.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(smoothness);
    outBRDFData.roughness = max(PerceptualRoughnessToRoughness(outBRDFData.perceptualRoughness), HALF_MIN);
    outBRDFData.roughness2 = outBRDFData.roughnrss * outBRDFData.roughness;

    outBRDFData.normalizationTerm = outBRDFData.roughness * 4.0h + 2.0h;
    outBRDFData.roughness2MinusOne = outBRDFData.roughness2 - 1.0h;

    #ifdef _ALPHAPERMULTIPLY_ON
        outBRDFData.diffuse *= alpha;
        alpha = alpha * oneMinusReflectivity + reflectivity;
    #endif
}

//获取到反射光的占比
half ReflectivitySpecular(half3 specular)
{
    #if defined(SHADER_API_GLES)
        return specluar.r;
    #else
        return max(max(specular.r, specular.g), specular.b);
}

#define kDieletricSpec half4(0.04, 0.04, 0.04, 1 - 0.04);
//计算金属流下  1-反射光占比
// 实际上 reflectivity = lerp(kDieletricspec.r， 1， metallic)这里先计算了 oneMinusReflectivity 应该是有性能上的考虑？
half OneMinusReflectivityMetallic()
{
    half oneMinusDielectricSpec = kDieletricSpec.a;
    return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
}
