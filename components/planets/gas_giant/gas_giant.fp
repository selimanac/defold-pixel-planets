
varying mediump vec2 var_texcoord0;

uniform sampler2D colorscheme;
uniform sampler2D dark_colorscheme;

uniform lowp vec4 transform;
uniform lowp vec4 generic;
uniform lowp vec4 border;
uniform lowp vec4 lights;

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

float turbulence(vec2 uv)
{
    float c_noise = 0.0;

    // more iterations for more turbulence
    for (int i = 0; i < 10; i++)
    {
        c_noise += circleNoise((uv * transform.x * 0.3) + (float(i + 1) + 10.) + (vec2(generic.y * generic.z, 0.0)));
    }
    return c_noise;
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

    float light_d = distance(uv, lights.xy);

    // we use this value later to dither between colors
    bool dith = dither(uv, var_texcoord0);
    uv = rotate(uv, transform.z);

    // map to sphere
    uv = spherify(uv);

    // a band is just one dimensional noise
    float band = fbm(vec2(0.0, uv.y * transform.x * border.z));

    // turbulence value is circles on top of each other
    float turb = turbulence(uv);

    // by layering multiple noise values & combining with turbulence and bands
    // we get some dynamic looking shape
    float fbm1 = fbm(uv * transform.x);
    float fbm2 = fbm(uv * vec2(1.0, 2.0) * transform.x + fbm1 + vec2(-generic.y * generic.z, 0.0) + turb);

    // all of this is just increasing some contrast & applying light
    fbm2 *= pow(band, 2.0) * 7.0;
    float light = fbm2 + light_d * 1.8;
    fbm2 += pow(light_d, 1.0) - 0.3;
    fbm2 = smoothstep(-0.2, 4.0 - fbm2, light);

    fbm2 = mix(fbm2, fbm2 * 1.1, float(dith));

    // finally add colors
    float posterized = floor(fbm2 * 4.0) / 2.0;
    vec3 col = texture2D(dark_colorscheme, vec2(posterized - 1.0, uv.y)).rgb;

    col = mix(col, texture2D(colorscheme, vec2(posterized, uv.y)).rgb, float(fbm2 < 0.625) );

    float a = step(length(uv - vec2(0.5)), 0.5);
    gl_FragColor = vec4(col, a);
}
