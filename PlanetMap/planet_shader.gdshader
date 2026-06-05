// TODO: Mostly AI generated, come back and verify this better once I learn more about shaders
shader_type canvas_item;

uniform float pixel_count: hint_range(1.0, 512.0, 1.0) = 64.0;

uniform float rand_seed: hint_range(0.0, 1.0, 0.01);
uniform sampler2D gradient;

uniform vec3 atmosphere_color: source_color = vec3(0.55, 0.78, 1.0); // Atmosphere rim color

uniform float cloud_cover: hint_range(0.0, 1.0, 0.01) = 0.5; // Percentage of the planet covered by clouds, between 0 and 1
uniform float cloud_density: hint_range(0.0, 1.0, 0.01) = 0.5; // Overall density of clouds, between 0 and 1
uniform vec3 cloud_color: source_color = vec3(0.98, 0.96, 0.98); // Base color of clouds

uniform float land_cover: hint_range(0.0, 1.0, 0.01) = 0.45; // Percentage of the planet covered by land, between 0 and 1
uniform vec3 land_color_low: source_color = vec3(0.20, 0.34, 0.15); // Low elevation land color
uniform vec3 land_color_high: source_color = vec3(0.52, 0.46, 0.22); // High elevation land color
uniform float elevation_frequency: hint_range(2.0, 16.0, 0.1) = 7.0; // Terrain detail scale
uniform float elevation_strength: hint_range(0.0, 2.0, 0.01) = 1.0; // How strong the elevation effect is on land color
uniform float elevation_contrast: hint_range(0.4, 3.0, 0.01) = 1.2; // How sharp/flat the elevation distribution feels

uniform vec3 ocean_color_deep: source_color = vec3(0.07, 0.12, 0.24); // Deep ocean color
uniform vec3 ocean_color_shallow: source_color = vec3(0.11, 0.26, 0.39); // Shallow ocean color
uniform float ocean_average_depth: hint_range(0.0, 1.0, 0.01) = 0.6; // Average ocean depth, 0 = shallow world, 1 = deep world
uniform float ocean_depth_variation: hint_range(0.0, 1.0, 0.01) = 0.45; // Local ocean depth variation
uniform float ocean_depth_contrast: hint_range(0.4, 3.0, 0.01) = 1.25; // How sharp/flat the ocean depth distribution feels

float hash12(vec2 p) {
    vec2 seed = vec2(rand_seed, rand_seed * 1.731 + 0.37);
    return fract(sin(dot(p + seed, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = hash12(i);
    float b = hash12(i + vec2(1.0, 0.0));
    float c = hash12(i + vec2(0.0, 1.0));
    float d = hash12(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    vec2 shift = vec2(23.17, 11.53) + rand_seed * 13.0;

    for (int i = 0; i < 5; i++) {
        value += amplitude * noise(p);
        p = mat2(vec2(1.6, -1.2), vec2(1.2, 1.6)) * p + shift;
        amplitude *= 0.5;
    }

    return value;
}

mat2 rotate2d(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat2(vec2(c, s), vec2(-s, c));
}

vec2 cloud_warp(vec2 p, vec2 seed_offset, float density) {
	float warp_strength = mix(0.10, 0.32, density);
	float warp_x = fbm(p * 1.3 + seed_offset * 0.7);
	float warp_y = fbm(p * 1.3 + seed_offset * 1.1 + vec2(12.7, 4.3));
	return (vec2(warp_x, warp_y) - 0.5) * warp_strength;
}

vec4 get_color(vec2 uv, float disk_alpha) {
    vec2 p = uv * 2.0 - 1.0;
    float radius = length(p);

    vec2 seed_offset = vec2(rand_seed * 17.0 + 0.31, rand_seed * 29.0 + 1.17);
    float planet_variation = hash12(seed_offset);
    float tilt = mix(-0.8, 0.8, hash12(seed_offset + 2.0)) + planet_variation * 0.2;
    vec2 planet_space = rotate2d(tilt) * p;

    float limb = 1.0 - smoothstep(0.88, 1.0, radius);
    float ocean_ridges = fbm(planet_space * 2.0 + seed_offset * 0.7);
    float ocean_depth = fbm(planet_space * 4.5 - seed_offset * 0.35);

    float land_cover_value = clamp(land_cover, 0.0, 1.0);
    float continent_field = fbm(planet_space * mix(1.9, 3.4, planet_variation) + seed_offset * 2.3);
    continent_field += (0.5 - abs(planet_space.y)) * 0.12;
    float cover_threshold = mix(0.82, 0.28, land_cover_value);
    float threshold_jitter = mix(-0.08, 0.08, hash12(seed_offset + 4.0));
    float continent_threshold = clamp(cover_threshold + threshold_jitter, 0.15, 0.9);
    float continent_feather = mix(0.09, 0.05, land_cover_value);
    float continents = smoothstep(continent_threshold - continent_feather, continent_threshold + continent_feather, continent_field);
    continents *= 1.0 - smoothstep(0.86, 1.02, radius);

    float depth_center = clamp(ocean_average_depth, 0.0, 1.0);
    float depth_spread = clamp(ocean_depth_variation, 0.0, 1.0) * 2.0;
    float depth_value = clamp(depth_center + (ocean_depth - 0.5) * depth_spread, 0.0, 1.0);
    depth_value = pow(depth_value, ocean_depth_contrast);
    float shelf_mask = smoothstep(0.20, 0.88, ocean_ridges);
    float shallow_factor = clamp((1.0 - depth_value) * 0.75 + shelf_mask * 0.25, 0.0, 1.0);
    vec3 ocean_color = mix(ocean_color_deep, ocean_color_shallow, shallow_factor);

    float coast_distance = abs(continent_field - continent_threshold);
    float coast_blend = 1.0 - smoothstep(continent_feather * 0.4, continent_feather * 2.2, coast_distance);
    coast_blend *= (1.0 - continents);
    ocean_color = mix(ocean_color, ocean_color_shallow, coast_blend * 0.35);

    float base_elevation = fbm(planet_space * elevation_frequency + seed_offset * 3.1);
    float elevation = pow(clamp(base_elevation, 0.0, 1.0), elevation_contrast);
    elevation = clamp((elevation - 0.5) * elevation_strength + 0.5, 0.0, 1.0);
    vec3 land_color = mix(land_color_low, land_color_high, elevation);
    land_color += vec3(0.08, 0.06, 0.03) * (elevation - 0.5) * elevation_strength;
    land_color += vec3(0.03, 0.02, -0.01) * (continent_field - 0.5);

    vec3 planet_color = mix(ocean_color, land_color, continents);

    float cloud_cover_value = clamp(cloud_cover, 0.0, 1.0);
    float cloud_density_value = clamp(cloud_density, 0.0, 1.0);
    vec2 cloud_space = rotate2d(tilt * 0.18 + 0.9) * p;
    vec2 warp = cloud_warp(cloud_space, seed_offset, cloud_density_value);

    float coverage_scale = mix(1.5, 2.6, cloud_cover_value);
    float large_clouds = fbm(cloud_space * coverage_scale + warp + seed_offset * 1.7);
    float medium_clouds = fbm(cloud_space * mix(4.0, 6.0, cloud_density_value) + warp * 2.1 + seed_offset * 4.9);
    float fine_clouds = fbm(cloud_space * 10.0 + warp * 3.0 + seed_offset * 8.3);

    float latitude = 1.0 - abs(planet_space.y);
    float weather_belt = smoothstep(0.10, 0.90, latitude);
    float cloud_field = large_clouds * 0.62 + medium_clouds * 0.26 + fine_clouds * 0.12;
    cloud_field = mix(cloud_field, large_clouds, 0.55);

    float cloud_threshold = 1.0 - cloud_cover_value;
    float cloud_feather = mix(0.28, 0.08, cloud_density_value);
    float cloud_body = smoothstep(cloud_threshold - cloud_feather, cloud_threshold + cloud_feather, cloud_field);
    float cloud_halo = smoothstep(cloud_threshold - cloud_feather * 1.8, cloud_threshold + cloud_feather * 0.5, cloud_field) * 0.45;
    float cloud_texture = smoothstep(0.32, 0.86, medium_clouds + (fine_clouds - 0.5) * 0.35);
    float cloud_variation = mix(0.55, 1.0, cloud_density_value);
    float clouds = clamp((cloud_body + cloud_halo) * cloud_texture * cloud_variation * weather_belt, 0.0, 1.0);
    clouds *= smoothstep(1.0, 0.68, radius);

    vec3 cloud_tint = mix(cloud_color, vec3(1.0), 0.28 + 0.18 * cloud_texture);
    cloud_tint *= mix(0.78, 1.08, cloud_texture);

    planet_color = mix(planet_color, cloud_tint, clouds);
    planet_color = mix(planet_color, atmosphere_color, smoothstep(0.72, 1.0, radius) * 0.18);
    planet_color = mix(planet_color, planet_color * 1.12, limb * 0.08);

    float alpha = disk_alpha * limb;
    return vec4(planet_color, alpha);
}

void fragment() {
    float disk_alpha = texture(TEXTURE, UV).a;
    vec2 cell_uv;
    if (pixel_count <= 1.0) {
        cell_uv = UV;
    } else {
        float px = max(1.0, pixel_count);
        cell_uv = (floor(UV * px) + 0.5) / px;
    }
    COLOR = get_color(cell_uv, disk_alpha);
    if (COLOR.a < 0.75) {
        discard;
    }
}