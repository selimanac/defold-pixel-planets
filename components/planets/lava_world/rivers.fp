varying mediump vec2 var_texcoord0;

uniform lowp vec4 transform;
uniform lowp vec4 generic;
uniform lowp vec4 lights;
uniform lowp vec4 border;
uniform lowp vec4 extras;
uniform lowp vec4 color1;
uniform lowp vec4 color2;
uniform lowp vec4 color3;

const lowp vec2 circle_v = vec2(0.5);
const lowp vec2 dir_x = vec2(1.0, 0.0);
const lowp vec2 dir_y = vec2(0.0, 1.0);
const lowp vec2 dir_z = vec2(1.0, 1.0);

float rand(vec2 coord)
{
    coord = mod(coord, vec2(2.0, 1.0) * floor(transform.x + 0.5));
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
    lowp float value = 0.0;
    lowp float scale = 0.5;

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

bool dither(vec2 uv1, vec2 uv2)
{
    return mod(uv1.x + uv2.y, 2.0 / transform.y) <= 1.0 / transform.y;
}

void main()
{
    // pixelize uv
    lowp vec2 uv = floor(var_texcoord0 * transform.y) / transform.y;
    uv.y = 1.0 - uv.y;

    lowp float d_light = distance(uv, lights.xy);

    // cut out a circle
    lowp float d_circle = distance(uv, circle_v);
    lowp float a = step(d_circle, 0.5);

    // give planet a tilt
    uv = rotate(uv, transform.z);

    // map to sphere
    uv = spherify(uv);

    // some scrolling noise for landmasses
    lowp float fbm1 = fbm(uv * transform.x + vec2(generic.y * generic.z, 0.0));
    lowp float river_fbm = fbm(uv + fbm1 * 2.5);

    // increase contrast on d_light
    d_light = pow(d_light, 2.0) * 0.4;
    d_light -= d_light * river_fbm;

    river_fbm = step(extras.z, river_fbm);

    a *= step(extras.z, river_fbm);

    lowp vec3 c = color3.rgb * float(d_light >= border.y) +
                  color2.rgb * float(d_light >= border.x && d_light < border.y) +
                  color1.rgb * float(d_light < border.x);

    gl_FragColor = vec4(c, a);
}
