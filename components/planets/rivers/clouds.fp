
varying mediump vec2 var_texcoord0;

uniform lowp vec4 transform;
uniform lowp vec4 generic;
uniform lowp vec4 border;   
uniform lowp vec4 modify;
uniform lowp vec4 lights;

uniform lowp vec4 base_color;
uniform lowp vec4 outline_color;
uniform lowp vec4 shadow_base_color;
uniform lowp vec4 shadow_outline_color;

const lowp vec2 dir_x = vec2(1.0, 0.0);
const lowp vec2 dir_y = vec2(0.0, 1.0);
const lowp vec2 dir_z = vec2(1.0, 1.0);

float rand(vec2 coord)
{
    coord = mod(coord, vec2(1.0, 1.0) * floor(transform.x + 0.5));
    return fract(sin(dot(coord.xy, vec2(12.9898, 78.233))) * 15.5453 * generic.x);
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

float cloud_alpha(vec2 uv)
{
    float c_noise = 0.0;

    // more iterations for more turbulence
    for (int i = 0; i < 9; i++)
    {
        c_noise += circleNoise((uv * transform.x * 0.3) + (float(i + 1) + 10.) + (vec2(generic.y * generic.z, 0.0)));
    }
    float fbm = fbm(uv * transform.x + c_noise + vec2(generic.y * generic.z, 0.0));

    return fbm; // step(a_cutoff, fbm);
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
    // distance to light source
    float d_light = distance(uv, lights.xy);

    // cut out a circle
    float d_circle = distance(uv, vec2(0.5));
    float a = step(d_circle, 0.5);

    float d_to_center = distance(uv, vec2(0.5));

    uv = rotate(uv, transform.z);

    // map to sphere
    uv = spherify(uv);
    // slightly make uv go down on the right, and up in the left
    uv.y += smoothstep(0.0, modify.y, abs(uv.x - 0.4));

    float c = cloud_alpha(uv * vec2(1.0, transform.w));

   


    lowp vec3 result = outline_color.rgb * float(c <= modify.x + 0.03) + base_color.rgb * float(c > modify.x + 0.03);
    result = mix(result, shadow_base_color.rgb, float(d_light + c * 0.2 > border.x));
    result = mix(result, shadow_outline_color.rgb, float(d_light + c * 0.2 > border.y));

    c *= step(d_to_center, 0.5);
    gl_FragColor = vec4(result, step(modify.x, c) * a);
}
