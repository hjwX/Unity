
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
    Metallic工作流：使用_Metallic的值作为颜色的RGB部分

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