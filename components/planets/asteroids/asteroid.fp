varying mediump vec2 var_texcoord0;

uniform lowp vec4 transform;
uniform lowp vec4 generic;
uniform lowp vec4 lights;
uniform lowp vec4 color1;
uniform lowp vec4 color2;
uniform lowp vec4 color3;

float rand(vec2 coord)
{
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

// by Leukbaars from https://www.shadertoy.com/view/4tK3zR
float circleNoise(vec2 uv)
{
    float uv_y = floor(uv.y);
    uv.x += uv_y * .31;
    vec2 f = fract(uv);
    float h = rand(vec2(floor(uv.x), floor(uv_y)));
    float m = (length(f - 0.25 - (h * 0.5)));
    float r = h * 0.25;
    return m = smoothstep(r - .10 * r, r, m);
}

float crater(vec2 uv)
{
    float c = 1.0;
    for (int i = 0; i < 2; i++)
    {
        c *= circleNoise((uv * transform.x) + (float(i + 1) + 10.));
    }
    return 1.0 - c;
}

void main()
{

    vec2 uv = floor(var_texcoord0 * transform.y) / transform.y;
    uv.y = 1.0 - uv.y;

    // we use this val later to interpolate between shades
    bool dith = dither(uv, var_texcoord0);

    // distance from center
    float d = distance(uv, vec2(0.5));

    // optional transform.z, do this after the dither or the dither will look very messed up
    uv = rotate(uv, transform.z);

    // two noise values with one slightly offset according to light source, to create shadows later
    float n = fbm(uv * transform.x);
    float n2 = fbm(uv * transform.x + (rotate(lights.xy, transform.z) - 0.5) * 0.5);

    // step noise values to determine where the edge of the asteroid is
    // step cutoff value depends on distance from center
    float n_step = step(0.2, n - d);
    float n2_step = step(0.2, n2 - d);

    // with this val we can determine where the shadows should be
    float noise_rel = (n2_step + n2) - (n_step + n);

    // two crater values, again one extra for the shadows
    float c1 = crater(uv);
    float c2 = crater(uv + (lights.xy - 0.5) * 0.03);

    // now we just assign colors depending on noise values and crater values
    // base

    lowp vec3 c = mix(color2.rgb, color1.rgb, float(noise_rel < -0.06 || (noise_rel < -0.04 && dith)));
    c = mix(c, color3.rgb, float(noise_rel > 0.05 || (noise_rel > 0.03 && dith)));
    //crates
    c = mix(c, color2.rgb, float(c1 > 0.4));
    c = mix(c, color3.rgb, float(c2 < c1));

    gl_FragColor = vec4(c, n_step);
}
