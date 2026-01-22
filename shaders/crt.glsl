// CRT Shader for Love2D
// Vintage tube monitor effect

// External parameters from Lua
extern vec2 resolution;
extern float time;
extern float scanlineIntensity;
extern float curvature;
extern float vignetteIntensity;
extern float brightness;

// Barrel distortion for curved screen effect
vec2 curveScreen(vec2 uv) {
    uv = uv * 2.0 - 1.0;
    vec2 offset = abs(uv.yx) / vec2(curvature, curvature);
    uv = uv + uv * offset * offset;
    uv = uv * 0.5 + 0.5;
    return uv;
}

// Vignette effect (darkening at edges)
float vignette(vec2 uv) {
    float vignette = uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y);
    vignette = clamp(pow(vignette * 16.0, vignetteIntensity), 0.0, 1.0);
    return vignette;
}

// Scanlines effect
float scanline(vec2 uv) {
    float scanline = sin(uv.y * resolution.y * 2.0) * 0.5 + 0.5;
    scanline = mix(1.0, scanline, scanlineIntensity);
    return scanline;
}

// Subtle CRT flicker/glow
float flicker(float time) {
    return 1.0 - (sin(time * 120.0) * 0.005 + 0.005);
}

// Main shader function
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    // Apply barrel distortion
    vec2 curved_uv = curveScreen(texture_coords);

    // Check if coordinates are out of bounds after distortion
    if (curved_uv.x < 0.0 || curved_uv.x > 1.0 || curved_uv.y < 0.0 || curved_uv.y > 1.0) {
        return vec4(0.0, 0.0, 0.0, 1.0);
    }

    // Sample the texture with curved coordinates
    vec4 texColor = Texel(texture, curved_uv);

    // Apply scanlines
    float scanlineEffect = scanline(curved_uv);
    texColor.rgb *= scanlineEffect;

    // Apply vignette
    float vignetteEffect = vignette(curved_uv);
    texColor.rgb *= vignetteEffect;

    // Apply subtle flicker
    float flickerEffect = flicker(time);
    texColor.rgb *= flickerEffect;

    // Slight chromatic aberration (color separation at edges)
    float aberration = 0.002;
    float distFromCenter = length(curved_uv - 0.5);
    if (distFromCenter > 0.3) {
        vec2 direction = normalize(curved_uv - 0.5) * aberration;
        float r = Texel(texture, curved_uv + direction).r;
        float b = Texel(texture, curved_uv - direction).b;
        texColor.r = mix(texColor.r, r, (distFromCenter - 0.3) * 2.0);
        texColor.b = mix(texColor.b, b, (distFromCenter - 0.3) * 2.0);
    }

    // Adjust brightness
    texColor.rgb *= brightness;

    // Subtle phosphor glow simulation
    texColor.rgb += vec3(0.02, 0.02, 0.01) * scanlineEffect;

    return texColor * color;
}
