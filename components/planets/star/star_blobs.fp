
varying mediump vec2 var_texcoord0;

uniform lowp vec4 transform;
uniform lowp vec4 generic;
uniform lowp vec4 circles;

uniform lowp vec4 color;

const lowp vec2 dir_x = vec2(1.0, 0.0);
const lowp vec2 dir_y = vec2(0.0, 1.0);
const lowp vec2 dir_z = vec2(1.0, 1.0);

float rand(vec2 co)
{
    co = mod(co, vec2(1.0, 1.0) * floor(transform.x + 0.5));
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 15.5453 * generic.x);
}

vec2 rotate(vec2 vec, float angle)
{
    vec -= vec2(0.5);
    vec *= mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle)));
    vec += vec2(0.5);
    return vec;
}

float circle(vec2 uv)
{
    float invert = 1.0 / circles.x;

    uv.x = (uv.x + invert * 0.5) * float(mod(uv.y, invert * 2.0) < invert);

    vec2 rand_co = floor(uv * circles.x) / circles.x;
    uv = mod(uv, invert) * circles.x;

    float r = rand(rand_co);
    r = clamp(r, invert, 1.0 - invert);
    float circle = distance(uv, vec2(r));
    return smoothstep(circle, circle + 0.5, invert * circles.y * rand(rand_co * 1.5));
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
    float scl = 0.5;

    for (int i = 0; i < int(generic.w); i++)
    {
        value += noise(coord) * scl;
        coord *= 2.0;
        scl *= 0.5;
    }
    return value;
}

bool dither(vec2 uv1, vec2 uv2)
{
    return mod(uv1.x + uv2.y, 2.0 / transform.y) <= 1.0 / transform.y;
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
    vec2 pixelized = floor(var_texcoord0 * transform.y) / transform.y;
    pixelized.y = 1.0 - pixelized.y;
    bool dith = dither(var_texcoord0, pixelized);

    vec2 uv = rotate(pixelized, transform.z);

    // angle from centered uv's
    float angle = atan(uv.x - 0.5, uv.y - 0.5);
    float d = distance(pixelized, vec2(0.5));

    float c = 0.0;
    for (int i = 0; i < 15; i++)
    {
        float r = rand(vec2(float(i)));
        vec2 circleUV = vec2(d, angle);
        c += circle(circleUV * transform.x - generic.y * generic.z - (1.0 / d) * 0.1 + r);
    }

    c *= 0.37 - d;
    c = step(0.07, c - d);

    gl_FragColor = vec4(vec3(color.rgb), c);
}
