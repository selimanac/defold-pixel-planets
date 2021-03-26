
varying mediump vec2 var_texcoord0;

uniform sampler2D colorramp;

uniform lowp vec4 transform;
uniform lowp vec4 generic;
uniform lowp vec4 modify;
uniform lowp vec4 circles;

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
    // pixelize uv
    vec2 pixelized = floor(var_texcoord0 * transform.y) / transform.y;
    pixelized.y = 1.0 - pixelized.y;
    // use dither val later to interpolate between alpha
    bool dith = dither(var_texcoord0, pixelized);

    pixelized = rotate(pixelized, transform.z);

    // counter transform.z against transform.z caused by the way uv's are made later
    vec2 uv = pixelized; // rotate(pixelized, -time  * time_speed);

    // angle from centered uv's
    float angle = atan(uv.x - 0.5, uv.y - 0.5) * 0.4;
    // distance from center
    float d = distance(pixelized, vec2(0.5));

    // we make uv circular here to have eternally outward moving stuff
    vec2 circleUV = vec2(d, angle);

    // two types of noise values
    float n = fbm(circleUV * transform.x - generic.y * generic.z);
    float nc = circle(circleUV * modify.w - generic.y * generic.z + n);

    nc *= 1.5;
    float n2 = fbm(circleUV * transform.x - generic.y + vec2(100, 100));
    nc -= n2 * 0.1;

    // our alpha, default 0
    float a = 0.0;

    a = 1.0 * float((nc > circles.z - circles.w + d && dith) && (1.0 - d > nc)) +
        1.0 * float((nc > circles.z + d) && (1.0 - d > nc));

    // use our two noise values to assign colors
    float interpolate = floor(n2 + nc);
    vec3 c = texture(colorramp, vec2(interpolate, 0.0)).rgb;

    // final step to not have everything appear from the center
    a *= step(n2 * 0.25, d);

    gl_FragColor = vec4(c, a);
}
