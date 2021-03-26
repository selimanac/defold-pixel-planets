varying mediump vec2 var_texcoord0;

uniform lowp vec4 transform;
uniform lowp vec4 generic;
uniform lowp vec4 lights;
uniform lowp vec4 modify;
uniform lowp vec4 border;
uniform lowp vec4 extras;

uniform lowp vec4 col1;
uniform lowp vec4 col2;
uniform lowp vec4 col3;
uniform lowp vec4 col4;
uniform lowp vec4 river_col;
uniform lowp vec4 river_col_dark;

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
    //	float z = pow(1.0 - dot(centered.xy, centered.xy), 0.5);
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
    vec2 uv = floor(var_texcoord0 * transform.y) / transform.y;
    uv.y = 1.0 - uv.y;

    float d_light = distance(uv, lights.xy);
    bool dith = dither(uv, var_texcoord0);
    float a = step(distance(vec2(0.5), uv), 0.5);

    // give planet a tilt
    uv = rotate(uv, transform.z);

    // map to sphere
    uv = spherify(uv);

    // some scrolling noise for landmasses
    vec2 base_fbm_uv = (uv)*transform.x + vec2(generic.y * generic.z, 0.0);

    // use multiple fbm's at different places so we can determine what color land
    // gets
    float fbm1 = fbm(base_fbm_uv);
    float fbm2 = fbm(base_fbm_uv - lights.xy * fbm1);
    float fbm3 = fbm(base_fbm_uv - lights.xy * 1.5 * fbm1);
    float fbm4 = fbm(base_fbm_uv - lights.xy * 2.0 * fbm1);

    float river_fbm = fbm(base_fbm_uv + fbm1 * 6.0);
    river_fbm = step(extras.z, river_fbm);

    // transform.x of edge in which colors should be dithered
    float dither_border = (1.0 / transform.y) * modify.z;
    // lots of magic numbers here
    // you can mess with them, it changes the color distribution

    fbm4 = mix(fbm4, fbm4 * 0.9, float(d_light < border.x));
    fbm2 = mix(fbm2, fbm2 * 1.05, float(d_light > border.x));
    fbm3 = mix(fbm3, fbm3 * 1.05, float(d_light > border.x));
    fbm4 = mix(fbm4, fbm4 * 1.05, float(d_light > border.x));
    fbm2 = mix(fbm2, fbm2 * 1.3, float(d_light > border.y));
    fbm3 = mix(fbm3, fbm3 * 1.4, float(d_light > border.y));
    fbm4 = mix(fbm4, fbm4 * 1.8, float(d_light > border.y));
    fbm4 = mix(fbm4, fbm4 * 0.5, float((d_light > border.y) && (d_light < border.y + dither_border && dith)));

    // increase contrast on d_light
    d_light = pow(d_light, 2.0) * 0.4;

    vec3 result = col4.rgb;
    result = mix(result, col3.rgb, float(fbm4 + d_light < fbm1 * 1.5));
    result = mix(result, col2.rgb, float(fbm3 + d_light < fbm1 * 1.0));
    result = mix(result, col1.rgb, float(fbm2 + d_light < fbm1));
    result = mix(result, river_col_dark.rgb, float(river_fbm < fbm1 * 0.5));
    result = mix(result, river_col.rgb, float((river_fbm < fbm1 * 0.5) && (fbm4 + d_light < fbm1 * 1.5)));

    gl_FragColor = vec4(result, a);
}
