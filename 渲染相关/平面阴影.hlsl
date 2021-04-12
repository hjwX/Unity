平面阴影是一种简单的实时阴影实现，但是局限是只能在地面完全平坦的情况下使用，但是由于性能良好并且阴影质量较好，在移动端还是有较强的价值。

其实可以抽象求一条直线和一个平面的交点问题
平面的方程:    (p - p0) n = 0   
                p0为平面上的一点， n为平面的法向量，则满足这个公式的p就组成了该平面
直线的方程：   p = d*L + L0
                d为任意实数，L为直线的方向向量，L0为直线的起点，d在实数范围内计算出来的P构成了这一条直线

由这两个公式: (d*L + L0 - p0) * n = 0
            d = (p0*n - L0*n) /L*n

在shader中计算的时候
    平面表示为(0,1,0,w),其中前面的xyz分量代表了表面的法向量 w = p0*n其实就是原点到平面的距离
    光线的方向直线的方程，在shader中可以找MainLight获得光线的方向LightDir
    L0可以取该点本身，所以我们要计算出点在世界的坐标

v2f vert(appdata v)
{
    v2f o;
    Light mainLight = GetMainLight();
    //获取到了灯光的方向
    float3 lightDir = normalize(mainLight.direction);
    float3 worldpos = TransformObjectToWorld(v.vertex);
    //带入公式得到d
    float distance = (_ShadowPlane.w - dot(_ShadowPlane.xyz, worldpos))/dot(lightDir, _ShadowPlane.xyz);
    //计算出阴影位置
    float3 shadowpos = worldpos + distance * lightDir.xyz;
    o.position = TransformWorldToHClip(shadowpos);
    o.worldpos = shadowpos;
}

float4 frag(v2f i) : SV_TARGET
{
    //获取到物体做平面上的投影坐标， 用来后面做w的渐变
    float center = float3(UNITY_MATRIX_M[0].w, _ShadowPlane.w, UNITY_MATRIX_M[2].w);
    float4 color = (0.0, 0.0, 0.0, 1);
    color.w = 1.0 - saturate(distance(center - i.worldpos) * _ShadowFalloff);
    return color;
}
