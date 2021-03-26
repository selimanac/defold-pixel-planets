

varying mediump vec2 var_texcoord0;

lowp vec2 offset = vec2(0.0);
uniform mediump vec4 time;

float rand(vec2 coord)
{
    return fract(sin(dot(coord.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 rotate(vec2 coord, float angle)
{
    coord -= 0.5;
    coord *= mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle)));
    return coord + 0.5;
}

void main()
{
    vec2 uv = rotate(var_texcoord0, time.x * 0.2);
    vec4 col = vec4(1.0) + rand(var_texcoord0 + vec2(time.x * 0.0000001, 0.0)) * 0.03;

    col = col * vec4(abs(sin(uv.x * cos(offset.x) + time.x * 0.105)),
                     abs(sin((cos(uv.x + uv.y) + cos(offset.x + offset.y) + time.x * 0.059))),
                     abs(cos(uv.y * sin(offset.y) + time.x * 0.0253)), 1.0);

    col = mix(col, vec4(0.0, 0.0, 0.0, 1.0), 0.88);

    gl_FragColor = col;
}
