#version 330

// ===== USER TUNING =====
// Minimum brightness floor in deep shadow
const float SHADOW_FLOOR = 0.10;

// Day sky exposure multiplier (skylight only)
const float DAY_EXPOSURE = 1.95;

// Block light boost. 1.0 = vanilla
const float BLOCK_STRENGTH = 2.80;

// Non-linear boost curve for block light
const float BLOCK_BOOST_POWER = 5.0;

// Post-lightmap contrast
const float LIGHT_CONTRAST = 0.78;

// ===== LIGHT COLOR TUNING =====
const vec3  BLOCK_LIGHT_COLOR    = vec3(1.00, 0.82, 0.52);
const float BLOCK_COLOR_STRENGTH = 1.35;

const vec3  SKY_LIGHT_COLOR      = vec3(0.72, 0.90, 1.12);
const float SKY_COLOR_STRENGTH   = 1.28;

layout(std140) uniform LightmapInfo {
    float AmbientLightFactor;
    float SkyFactor;
    float BlockFactor;
    float NightVisionFactor;
    float DarknessScale;
    float DarkenWorldFactor;
    float BrightnessFactor;
    vec3 SkyLightColor;
    vec3 AmbientColor;
} lightmapInfo;

in vec2 texCoord;
out vec4 fragColor;

float get_brightness(float level) {
    return level / (4.0 - 3.0 * level);
}

vec3 notGammaSafe(vec3 color) {
    float maxComponent = max(max(color.x, color.y), color.z);
    if (maxComponent <= 0.0) {
        return color;
    }
    float maxInverted = 1.0 - maxComponent;
    float maxScaled = 1.0 - maxInverted * maxInverted * maxInverted * maxInverted;
    return color * (maxScaled / maxComponent);
}

void main() {
    float block_brightness = get_brightness(floor(texCoord.x * 16.0) / 15.0) * lightmapInfo.BlockFactor;
    float sky_brightness = get_brightness(floor(texCoord.y * 16.0) / 15.0) * lightmapInfo.SkyFactor;

    // ===== DAY_EXPOSURE (skylight only) =====
    sky_brightness = clamp(sky_brightness * DAY_EXPOSURE, 0.0, 1.0);

    // ===== BLOCK BOOST =====
    if (lightmapInfo.AmbientLightFactor == 0.0) {
        float b = clamp(block_brightness, 0.0, 1.0);
        float boosted = 1.0 - pow(1.0 - b, BLOCK_BOOST_POWER);
        float t = clamp(BLOCK_STRENGTH - 1.0, 0.0, 2.5);
        block_brightness = mix(b, boosted, t);
    }

    vec3 color = vec3(
        block_brightness,
        block_brightness * ((block_brightness * 0.6 + 0.4) * 0.6 + 0.4),
        block_brightness * (block_brightness * block_brightness * 0.6 + 0.4)
    );

    // ===== COLOR: BLOCK LIGHT =====
    float blockMask = clamp(block_brightness, 0.0, 1.0) * BLOCK_COLOR_STRENGTH;
    color *= mix(vec3(1.0), BLOCK_LIGHT_COLOR, blockMask);

    // Vanilla ambient term
    color = mix(color, lightmapInfo.AmbientColor, lightmapInfo.AmbientLightFactor);

    // ===== COLOR: SKY LIGHT =====
    vec3 skyAdd = lightmapInfo.SkyLightColor * sky_brightness;
    skyAdd *= mix(vec3(1.0), SKY_LIGHT_COLOR, SKY_COLOR_STRENGTH);

    color += skyAdd;
    color = mix(color, vec3(0.75), 0.00);

    if (lightmapInfo.AmbientLightFactor == 0.0) {
        vec3 darkened_color = color * vec3(0.7, 0.6, 0.6);
        color = mix(color, darkened_color, lightmapInfo.DarkenWorldFactor);
    }

    if (lightmapInfo.NightVisionFactor > 0.0) {
        float max_component = max(color.r, max(color.g, color.b));
        if (max_component > 0.0 && max_component < 1.0) {
            vec3 bright_color = color / max_component;
            color = mix(color, bright_color, lightmapInfo.NightVisionFactor);
        }
    }

    if (lightmapInfo.AmbientLightFactor == 0.0) {
        color -= vec3(lightmapInfo.DarknessScale);
    }

    color = clamp(color, 0.0, 1.0);

    vec3 ng = notGammaSafe(color);
    color = mix(color, ng, lightmapInfo.BrightnessFactor);

    // ===== CONTRAST + SHADOW FLOOR =====
    color = pow(color, vec3(LIGHT_CONTRAST));
    color = max(color, vec3(SHADOW_FLOOR));
    color = clamp(color, 0.0, 1.0);

    fragColor = vec4(color, 1.0);
}