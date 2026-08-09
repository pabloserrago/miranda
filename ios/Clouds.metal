#include <metal_stdlib>
using namespace metal;

// Procedural cloud background for NoisyBackgroundView.CloudLayer.
// Fractal brownian motion (FBM) over value noise, mapped onto three
// theme color stops (low → mid → high noise value). Static by design;
// `seed` offsets the noise domain so each preset gets its own clouds.

static float hash21(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

static float valueNoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    float a = hash21(i);
    float b = hash21(i + float2(1.0, 0.0));
    float c = hash21(i + float2(0.0, 1.0));
    float d = hash21(i + float2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

static float fbm(float2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    // Rotate between octaves to break up axis-aligned artifacts.
    float2x2 rot = float2x2(0.8, 0.6, -0.6, 0.8);
    for (int i = 0; i < 5; i++) {
        value += amplitude * valueNoise(p);
        p = rot * p * 2.0;
        amplitude *= 0.5;
    }
    return value;
}

[[stitchable]] half4 clouds(float2 position, half4 color, float2 size,
                            half4 colorA, half4 colorB, half4 colorC,
                            float scale, float seed,
                            float edgeLow, float edgeHigh) {
    float2 uv = position / max(size.x, 1.0);
    float n = fbm(uv * scale + float2(seed * 17.0, seed * 31.0));
    // FBM output concentrates around ~0.5; the edges control cloud contrast
    // (narrower range = punchier clouds, wider = mistier).
    float t = smoothstep(edgeLow, edgeHigh, n);
    half4 low = mix(colorA, colorB, half4(smoothstep(0.0, 0.6, t)));
    half4 c   = mix(low,    colorC, half4(smoothstep(0.5, 1.0, t)));
    return half4(c.rgb, color.a);
}
