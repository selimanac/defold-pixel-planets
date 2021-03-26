
varying mediump vec2 var_texcoord0;

uniform lowp vec4 transform;
uniform lowp vec4 generic;
uniform lowp vec4 lights;
uniform lowp vec4 border;

uniform vec4 color1;
uniform vec4 color2;

float rand(vec2 coord)
{
    coord = mod(coord, vec2(1.0, 1.0) * floor(transform.x + 0.5));
    return fract(sin(dot(coord.xy, vec2(12.9898, 78.233))) * 15.5453 * generic.x);
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
        c *= circleNoise((uv * transform.x) + (float(i + 1) + 10.) + vec2(generic.y * generic.z, 0.0));
    }
    return 1.0 - c;
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

    // check distance from center & distance to light
    float d_circle = distance(uv, vec2(0.5));
    float d_light = distance(uv, vec2(lights.xy));
    // cut out a circle
    float a = step(d_circle, 0.5);

    uv = rotate(uv, transform.z);
    uv = spherify(uv);

    float c1 = crater(uv);
    float c2 = crater(uv + (lights.xy - 0.5) * 0.03);
    vec3 col = color1.rgb;

    a *= step(0.5, c1);

    col = mix(col, color2.rgb, float(c2 < c1 - (0.5 - d_light) * 2.0));
    col = mix(col, color2.rgb, float(d_light > border.x));
    
    // cut out a circle
    a *= step(d_circle, 0.5);
    gl_FragColor = vec4(col, a);
}
