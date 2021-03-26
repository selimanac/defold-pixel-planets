
varying mediump vec2 var_texcoord0;

uniform lowp vec4 transform;
uniform lowp vec4 generic;
uniform lowp vec4 lights;
uniform lowp vec4 border;
uniform lowp vec4 modify;

uniform vec4 color1;
uniform vec4 color2;
uniform vec4 color3;

float rand(vec2 coord)
{
    // land has to be tiled
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
    float b = rand(i + vec2(1.0, 0.0));
    float c = rand(i + vec2(0.0, 1.0));
    float d = rand(i + vec2(1.0, 1.0));

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

bool dither(vec2 uv1, vec2 uv2)
{
    return mod(uv1.x + uv2.y, 2.0 / transform.y) <= 1.0 / transform.y;
}

vec2 rotate(vec2 coord, float angle)
{
    coord -= 0.5;
    coord *= mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle)));
    return coord + 0.5;
}

vec2 spherify(vec2 uv)
{
    vec2 centered = uv * 2.0 - 1.0;
    float z = sqrt(1.0 - dot(centered.xy, centered.xy));
    vec2 sphere = centered / (z + 1.0);
    return sphere * 0.5 + 0.5;
}

void main()
{
    // pixelize uv
    vec2 uv = floor(var_texcoord0 * transform.y) / transform.y;
    uv.y = 1.0 - uv.y;

    bool dith = dither(uv, var_texcoord0);

    uv = spherify(uv);
    uv = rotate(uv, transform.z);
    // check distance from center & distance to light
    float d_circle = distance(uv, vec2(0.5));
    float d_light = distance(uv, vec2(lights.xy));

    // cut out a circle
    float a = step(d_circle, 0.5);

    // get a noise value with light distance added
    d_light += fbm(uv * transform.x + vec2(generic.y * generic.z, 0.0)) *
               0.3; // change the magic 0.3 here for different light strengths

    // size of edge in which colors should be dithered
    float dither_border = (1.0 / transform.y) * modify.z;



	lowp vec3 c = color3.rgb * float(d_light >= border.y) +
                  color2.rgb * float(d_light >= border.x && d_light < border.y) +
                  color1.rgb * float(d_light < border.x);

    c = mix(c, color1.rgb, float(d_light > border.x && d_light < border.x + dither_border && dith));
    c = mix(c, color2.rgb, float(d_light > border.y && d_light < border.y + dither_border && dith));

    gl_FragColor = vec4(c, a);
}
