#pragma header

uniform float zoom;

uniform float camX;
uniform float camY;
uniform float camZ;

uniform float rotX;
uniform float rotY;
uniform float rotZ;

uniform float offsetX;
uniform float offsetY;

const float PI = 3.14159265;

mat3 rotateX(float deg)
{
    float a = radians(deg);

    float s = sin(a);
    float c = cos(a);

    return mat3(
        vec3(1.0, 0.0, 0.0),
        vec3(0.0, c, -s),
        vec3(0.0, s, c)
    );
}

mat3 rotateY(float deg)
{
    float a = radians(deg);

    float s = sin(a);
    float c = cos(a);

    return mat3(
        vec3(c, 0.0, s),
        vec3(0.0, 1.0, 0.0),
        vec3(-s, 0.0, c)
    );
}

mat3 rotateZ(float deg)
{
    float a = radians(deg);

    float s = sin(a);
    float c = cos(a);

    return mat3(
        vec3(c, -s, 0.0),
        vec3(s, c, 0.0),
        vec3(0.0, 0.0, 1.0)
    );
}

vec2 mirrorRepeat(vec2 uv)
{
    if ((uv.x > 1.0 || uv.x < 0.0) && abs(mod(uv.x, 2.0)) > 1.0)
        uv.x = (-uv.x) + 1.0;

    if ((uv.y > 1.0 || uv.y < 0.0) && abs(mod(uv.y, 2.0)) > 1.0)
        uv.y = (-uv.y) + 1.0;

    return vec2(
        abs(mod(uv.x, 1.0)),
        abs(mod(uv.y, 1.0))
    );
}

void main()
{
    vec2 iResolution = vec2(1280.0, 720.0);

    vec2 fragCoord = openfl_TextureCoordv.xy * iResolution;

    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    // camera position
    vec3 ro = vec3(camX, camY, camZ);

    // perspective ray
    vec3 rd = normalize(vec3(uv, -zoom));

    // full 360 rotations
    mat3 rot =
        rotateX(rotX) *
        rotateY(rotY) *
        rotateZ(rotZ);

    rd *= rot;

    // avoid divide by zero
    if(abs(rd.z) < 0.0001)
    {
        gl_FragColor = vec4(0.0);
        return;
    }

    // plane hit
    float t = -ro.z / rd.z;

    vec3 p = ro + rd * t;

    vec2 finalUV = p.xy;

    finalUV += vec2(offsetX, offsetY);

    finalUV += 0.5;

    finalUV = mirrorRepeat(finalUV);

    gl_FragColor = flixel_texture2D(bitmap, finalUV);
}