
varying mediump vec2 var_texcoord0;

uniform sampler2D colorscheme;
uniform sampler2D dark_colorscheme;

uniform lowp vec4 transform;
uniform lowp vec4 generic;
uniform lowp vec4 lights;
uniform lowp vec4 modify;
uniform lowp vec4 extras;

const lowp vec2 dir_x = vec2(1.0, 0.0);
const lowp vec2 dir_y = vec2(0.0, 1.0);
const lowp vec2 dir_z = vec2(1.0, 1.0);

float rand(vec2 coord)
{
    coord = mod(coord, vec2(2.0, 1.0) * floor(transform.x + 0.5));
    return fract(sin(dot(coord.xy, vec2(12.9898, 78.233))) * 43758.5453 * generic.x);
}

float noise(vec2 coord)
{
    vec2 i = floor(coord);
    vec2 f = fract(coord);

    float a = rand(i);
    float b = rand(i + dir_x);
    float c = rand(i + dir_y);
    float d = rand(i + dir_z);

    vec2 cubic = f * f * (3.0 - 2.0 * f);

    return mix(a, b, cubic.x) + (c - a) * cubic.y * (1.0 - cubic.x) + (d - b) * cubic.x * cubic.y;
}

float fbm(vec2 coord)
{
    float value = 0.0;
    float scale = 0.5;

    for (int i = 0; i < int(generic.w); i++)
    {
        value += noise(coord) * scale;
        coord *= 2.0;
        scale *= 0.5;
    }
    return value;
}

// by Leukbaars from https://www.shadertoy.com/view/4tK3zR
float circleNoise(vec2 uv)
{
    float uv_y = floor(uv.y);
    uv.x += uv_y * .31;
    vec2 f = fract(uv);
    float h = rand(vec2(floor(uv.x), floor(uv_y)));
    float m = (length(f - 0.25 - (h * 0.5)));
    float r = h * 0.25;
    return smoothstep(0.0, r, m * 0.75);
}

bool dither(vec2 uv_pixel, vec2 uv_real)
{
    return mod(uv_pixel.x + uv_real.y, 2.0 / transform.y) <= 1.0 / transform.y;
}

vec2 spherify(vec2 uv)
{
    vec2 centered = uv * 2.0 - 1.0;
    float z = sqrt(1.0 - dot(centered.xy, centered.xy));
    vec2 sphere = centered / (z + 1.0);
    return sphere * 0.5 + 0.5;
}

vec2 rotate(vec2 coord, float angle)
{
    coord -= 0.5;
    coord *= mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle)));
    return coord + 0.5;
}

void main()
{
    // pixelize uv
    vec2 uv = floor(var_texcoord0 * transform.y) / transform.y;
    uv.y = 1.0 - uv.y;
    // we use this value later to dither between colors
    bool dith = dither(var_texcoord0, uv);

    float light_d = distance(uv, lights.xy);
    uv = rotate(uv, transform.z);

    // center is used to determine ring position
    vec2 uv_center = uv - vec2(0.0, 0.5);

    // tilt ring
    uv_center *= vec2(1.0, extras.y);
    float center_d = distance(uv_center, vec2(0.5, 0.0));

    // cut out 2 circles of different transform.xs and only intersection of the 2.
    float ring = smoothstep(0.5 - extras.x * 2.0, 0.5 - extras.x, center_d);
    ring *= smoothstep(center_d - extras.x, center_d, 0.4);

    ring = mix(ring, ring * step(1.0 / modify.w, distance(uv, vec2(0.5))), float(uv.y < 0.5));

    // rotate material in the ring
    uv_center = rotate(uv_center + vec2(0, 0.5), generic.y * generic.z);
    // some noise
    ring *= fbm(uv_center * transform.x);

    // apply some colors based on final value
    float posterized = floor((ring + pow(light_d, 2.0) * 2.0) * 4.0) / 4.0;

    vec3 col = texture2D(dark_colorscheme, vec2(posterized - 1.0, uv.y)).rgb;
    col = mix(col, texture2D(colorscheme, vec2(posterized, uv.y)).rgb, float(posterized <= 1.0));

    float ring_a = step(0.28, ring);
    gl_FragColor = vec4(col, ring_a);
}
