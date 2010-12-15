struct Light {
    vec3 position;
    vec3 ambientColor;
    vec3 diffuseColor;
    vec2 attenuationFactors; // constant, linear.
};

struct Material {
    vec3 specularColor;
    float shininess;
};

uniform mat4 uModelviewMatrix;
uniform mat4 uProjectionMatrix;
uniform mat4 uNormalMatrix;

uniform Light uLight;
uniform Material uMaterial;

uniform lowp float uColorFade;
uniform highp vec2 uContentsScale;

uniform bool uFlipContentsX;

uniform vec4 uZoomedTextureRect;

attribute highp vec2 aTextureCoordinate;
attribute highp vec4 aPosition;
attribute vec4 aNormal;

varying lowp vec3 vColor;
varying highp vec2 vPaperCoordinate;
varying highp vec2 vContentsCoordinate;
varying highp vec2 vZoomedContentsCoordinate;

const float cFZero = 0.0;
const float cFOne = 1.0;

const vec3 defaultMaterialAmbient = vec3(0.2, 0.2, 0.2);
const vec3 defaultMaterialDiffuse = vec3(0.8, 0.8, 0.8);

vec3 lightingEquation(in vec3 vertexPosition, in vec3 normal)
{
    vec3 lightPosition = uLight.position;
    vec3 lightDirection = lightPosition - vertexPosition;
    float lightDistance = length(lightDirection);
    lightDirection = normalize(lightDirection);

    // Ambient.
    vec3 buildColor = uLight.ambientColor * defaultMaterialAmbient;

    // Diffuse.
    float normalDotLight = max(cFZero, dot(normal, lightDirection));
    buildColor += normalDotLight * uLight.diffuseColor * defaultMaterialDiffuse;

    // Specular.
    vec3 halfVector = normalize(lightDirection + vec3(cFZero, cFZero, cFOne));
    float normalDotHalf = min(dot(normal, halfVector), cFZero);
    buildColor += pow(normalDotHalf, uMaterial.shininess) * uMaterial.specularColor;

    // Calculate attenuation using vector math to do all components together.
    vec2 attenuationMultiples = vec2(cFOne, lightDistance);
    buildColor /= dot(attenuationMultiples, uLight.attenuationFactors);

    return clamp(buildColor, cFZero, cFOne);
}

void main()
{
    vec4 projectedPosition = uModelviewMatrix * aPosition;
    vec4 projectedNormal = uNormalMatrix * aNormal;

    vColor = lightingEquation(projectedPosition.xyz / projectedPosition.w,
                              normalize(projectedNormal.xyz / projectedNormal.w)) * uColorFade;

    vPaperCoordinate = aTextureCoordinate;
    vContentsCoordinate = vec2(abs(float(uFlipContentsX) - aTextureCoordinate.x), aTextureCoordinate.y);
    vZoomedContentsCoordinate = vec2((vContentsCoordinate.x - uZoomedTextureRect.x) / uZoomedTextureRect.z,
                                     (vContentsCoordinate.y - uZoomedTextureRect.y) / uZoomedTextureRect.w);

    vContentsCoordinate *= uContentsScale;

    gl_Position = uProjectionMatrix * projectedPosition;
}