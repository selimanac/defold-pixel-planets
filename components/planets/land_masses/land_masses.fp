
varying mediump vec2 var_texcoord0;

uniform lowp vec4 transform;
uniform lowp vec4 lights;
uniform lowp vec4 generic;
uniform lowp vec4 border;
uniform lowp vec4 extras;

uniform lowp vec4 col1;
uniform lowp vec4 col2;
uniform lowp vec4 col3;
uniform lowp vec4 col4;

const lowp vec2 dir_x = vec2(1.0, 0.0);
const lowp vec2 dir_y = vec2(0.0, 1.0);
const lowp vec2 dir_z = vec2(1.0, 1.0);

float rand(vec2 coord)
{
    // land has to be tiled (or the contintents on this planet have to be changing very fast)
    // tiling only works for integer values, thus the rounding
    // it would probably be better to only allow integer sizes
    // multiply by vec2(2,1) to simulate planet having another side
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
    vec2 uv = floor(var_texcoord0 * transform.y) / transform.y;
    uv.y = 1.0 - uv.y;

    float d_light = distance(uv, lights.xy);
    uv = rotate(uv, transform.z);
    uv = spherify(uv);
    vec2 base_fbm_uv = (uv)*transform.x + vec2(generic.y * generic.z, 0.0);

    float fbm1 = fbm(base_fbm_uv);
    float fbm2 = fbm(base_fbm_uv - lights.xy * fbm1);
    float fbm3 = fbm(base_fbm_uv - lights.xy * 1.5 * fbm1);
    float fbm4 = fbm(base_fbm_uv - lights.xy * 2.0 * fbm1);

    // lots of magic numbers here
    // you can mess with them, it changes the color distribution
    if (d_light < border.x)
    {
        fbm4 *= 0.9;
    }
    if (d_light > border.x)
    {
        fbm2 *= 1.05;
        fbm3 *= 1.05;
        fbm4 *= 1.05;
    }
    if (d_light > border.y)
    {
        fbm2 *= 1.3;
        fbm3 *= 1.4;
        fbm4 *= 1.8;
    }

    d_light = pow(d_light, 2.0) * 0.1;

    lowp vec3 result = col4.rgb;
    result = mix(result, col3.rgb, float(fbm4 + d_light < fbm1));
    result = mix(result, col2.rgb, float(fbm3 + d_light < fbm1));
    result = mix(result, col1.rgb, float(fbm2 + d_light < fbm1));

    gl_FragColor = vec4(result, step(extras.z, fbm1));
}
