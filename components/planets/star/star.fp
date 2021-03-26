varying mediump vec2 var_texcoord0;

uniform lowp sampler2D colorramp;

uniform lowp vec4 transform;
uniform lowp vec4 generic;
uniform lowp vec4 extras;

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

vec2 Hash2(vec2 p)
{
    float t = (generic.y + 10.0) * .3;
    // p = mod(p, vec2(1.0,1.0)*round(transform.x));
    return vec2(noise(p), noise(p * vec2(.3135 + sin(t), .5813 - cos(t))));
}

// Tileable cell noise by Dave_Hoskins from shadertoy: https://www.shadertoy.com/view/4djGRh
float Cells(in vec2 p, in float numCells)
{
    p *= numCells;
    float d = 1.0e10;
    for (int xo = -1; xo <= 1; xo++)
    {
        for (int yo = -1; yo <= 1; yo++)
        {
            vec2 tp = floor(p) + vec2(float(xo), float(yo));
            tp = p - tp - Hash2(mod(tp, numCells / extras.w));
            d = min(d, dot(tp, tp));
        }
    }
    return sqrt(d);
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

    // use dither val later to mix between colors
    bool dith = dither(var_texcoord0, pixelized);

    pixelized = rotate(pixelized, transform.z);

    // spherify has to go after dither
    pixelized = spherify(pixelized);

    // use two different transform.xd cells for some variation
    // float Cells(in vec2 p, in float numCells)
    float n = Cells(pixelized - vec2(generic.y * generic.z * 2.0, 0), 10.0);
    n *= Cells(pixelized - vec2(generic.y * generic.z * 2.0, 0), 20.0);

    // adjust cell value to get better looking stuff
    n *= 2.;
    n = clamp(n, 0.0, 1.0);
    n = mix(n, n*1.3, dith);

    // constrain values 4 possibilities and then choose color based on those
    float interpolate = floor(n * 3.0) / 3.0;
    vec3 c = texture(colorramp, vec2(interpolate, 0.0)).rgb;

    // cut out a circle
    float a = step(distance(pixelized, vec2(0.5)), .5);

    gl_FragColor = vec4(c, a);
}
