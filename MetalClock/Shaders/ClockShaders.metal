#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

struct Uniforms {
    float2 resolution;
    float secondAngle;
    float minuteAngle;
    float hourAngle;
    float padding;
};

vertex VertexOut fullscreen_vertex(uint vertexID [[vertex_id]], const device float2 *positions [[buffer(0)]]) {
    VertexOut out;
    float2 pos = positions[vertexID];
    out.position = float4(pos, 0.0, 1.0);
    out.uv = pos * 0.5 + 0.5;
    return out;
}

float sdSegment(float2 p, float2 a, float2 b) {
    float2 pa = p - a;
    float2 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

float strokeAA(float distance, float halfWidth) {
    float w = fwidth(distance);
    return smoothstep(halfWidth + w, halfWidth - w, distance);
}

float fillAA(float distance) {
    float w = fwidth(distance);
    return smoothstep(w, -w, distance);
}

float4 over(float4 top, float4 under) {
    float outA = top.a + under.a * (1.0 - top.a);
    float3 outRGB = top.rgb * top.a + under.rgb * (1.0 - top.a);
    return float4(outRGB, outA);
}

fragment float4 clock_fragment(VertexOut in [[stage_in]], constant Uniforms &u [[buffer(0)]]) {
    float2 p = in.uv * 2.0 - 1.0;
    float aspect = u.resolution.x / u.resolution.y;
    p.x *= aspect;

    float ringRadius = 0.9;
    float ringThickness = 0.012;

    float4 outColor = float4(0.0);

    float ringDist = abs(length(p) - ringRadius);
    float ringAlpha = strokeAA(ringDist, ringThickness);

    float tickAlpha = 0.0;
    float tickWidth = 0.006;
    float tickLength = 0.08;
    for (int i = 0; i < 12; i++) {
        float angle = (float)i / 12.0 * (float)M_PI_F * 2.0;
        float2 dir = float2(sin(angle), cos(angle));
        float2 a = dir * (ringRadius - tickLength);
        float2 b = dir * (ringRadius - 0.015);
        float d = sdSegment(p, a, b);
        tickAlpha = max(tickAlpha, strokeAA(d, tickWidth));
    }

    float hourLength = 0.45;
    float minuteLength = 0.65;
    float secondLength = 0.78;

    float hourWidth = 0.04;
    float minuteWidth = 0.028;
    float secondWidth = 0.012;

    float2 hourDir = float2(sin(u.hourAngle), cos(u.hourAngle));
    float2 minuteDir = float2(sin(u.minuteAngle), cos(u.minuteAngle));
    float2 secondDir = float2(sin(u.secondAngle), cos(u.secondAngle));

    float2 hourA = -hourDir * 0.05;
    float2 hourB = hourDir * hourLength;
    float2 minuteA = -minuteDir * 0.08;
    float2 minuteB = minuteDir * minuteLength;
    float2 secondA = -secondDir * 0.1;
    float2 secondB = secondDir * secondLength;

    float hourDist = sdSegment(p, hourA, hourB);
    float minuteDist = sdSegment(p, minuteA, minuteB);
    float secondDist = sdSegment(p, secondA, secondB);

    float hourAlpha = strokeAA(hourDist, hourWidth);
    float minuteAlpha = strokeAA(minuteDist, minuteWidth);
    float secondAlpha = strokeAA(secondDist, secondWidth);

    float2 shadowOffset = float2(1.0 / u.resolution.x, -1.0 / u.resolution.y) * 2.0;
    float shadowStrength = 0.2;

    float hourShadow = strokeAA(sdSegment(p - shadowOffset, hourA, hourB), hourWidth + 0.01) * shadowStrength;
    float minuteShadow = strokeAA(sdSegment(p - shadowOffset, minuteA, minuteB), minuteWidth + 0.01) * shadowStrength;
    float secondShadow = strokeAA(sdSegment(p - shadowOffset, secondA, secondB), secondWidth + 0.01) * (shadowStrength * 0.9);

    float capRadius = 0.04;
    float capDist = length(p) - capRadius;
    float capAlpha = fillAA(capDist);

    float4 ringLayer = float4(float3(0.95), ringAlpha * 0.8);
    float4 tickLayer = float4(float3(0.95), tickAlpha * 0.6);
    float4 hourShadowLayer = float4(float3(0.0), hourShadow);
    float4 minuteShadowLayer = float4(float3(0.0), minuteShadow);
    float4 secondShadowLayer = float4(float3(0.0), secondShadow);

    float4 hourLayer = float4(float3(0.97, 0.96, 0.94), hourAlpha);
    float4 minuteLayer = float4(float3(0.98, 0.97, 0.95), minuteAlpha);
    float4 secondLayer = float4(float3(0.98, 0.35, 0.25), secondAlpha * 0.9);
    float4 capLayer = float4(float3(0.98), capAlpha);

    outColor = over(ringLayer, outColor);
    outColor = over(tickLayer, outColor);

    outColor = over(hourShadowLayer, outColor);
    outColor = over(hourLayer, outColor);

    outColor = over(minuteShadowLayer, outColor);
    outColor = over(minuteLayer, outColor);

    outColor = over(secondShadowLayer, outColor);
    outColor = over(secondLayer, outColor);

    outColor = over(capLayer, outColor);

    return outColor;
}
