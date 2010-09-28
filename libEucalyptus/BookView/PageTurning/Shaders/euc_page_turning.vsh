struct Light {
    vec3 position;
    vec4 ambientColor;
    vec4 diffuseColor;
    vec2 attenuationFactors; // constant, linear.
};

struct Material {
    vec4 specularColor;
    float shininess;
};

uniform mat4 uModelviewMatrix;
uniform mat4 uProjectionMatrix;
uniform mat4 uNormalMatrix;

uniform Light uLight;
uniform Material uMaterial;

attribute vec2 aPageTextureCoordinate;
attribute vec2 aContentsTextureCoordinate;
attribute vec4 aPosition;
attribute vec4 aNormal;

varying lowp vec4 vColor;
varying mediump vec2 vTextureCoordinate[2];

uniform lowp float uBackContentsBleed;

varying lowp float vBackContentsBleed;
varying lowp float vBackContentsBleedAddition;

const float cFZero = 0.0;
const float cFOne = 1.0;

const vec4 defaultMaterialAmbient = vec4(0.2, 0.2, 0.2, 1.0);
const vec4 defaultMaterialDiffuse = vec4(0.8, 0.8, 0.8, 1.0);

vec4 lightingEquation(in vec3 vertexPosition, in vec3 normal)
{    
    vec3 lightPosition = uLight.position;
    vec3 lightDirection = lightPosition - vertexPosition;
    float lightDistance = length(lightDirection);
    lightDirection = normalize(lightDirection);
    
    // Ambient.
    vec4 buildColor = uLight.ambientColor * defaultMaterialAmbient;
    
    // Diffuse.
    float normalDotLight = max(cFZero, dot(normal, lightDirection));
    buildColor += normalDotLight * uLight.diffuseColor * defaultMaterialDiffuse;
    
    // Specular.
    vec3 halfVector = normalize(lightDirection + vec3(cFZero, cFZero, cFOne));
    float normalDotHalf =  dot(normal, halfVector);
    if(normalDotHalf > cFZero) {
        buildColor += pow(normalDotHalf, uMaterial.shininess) * uMaterial.specularColor;
    }
    
    // Calculate attenuation using vector math to do all components together.
    vec2 attenuationMultiples = vec2(cFOne, lightDistance);
    float attenuationFactor = cFOne / dot(attenuationMultiples, uLight.attenuationFactors);
    buildColor *= attenuationFactor;
    
    return clamp(buildColor, cFZero, cFOne);
}

void main()
{
    vec4 projectedPosition = uModelviewMatrix * aPosition;
    vec4 projectedNormal = uNormalMatrix * aNormal;
    
    if(projectedNormal.z <= cFZero) {
        vBackContentsBleed = uBackContentsBleed;
        vBackContentsBleedAddition = cFOne - uBackContentsBleed;
    } else {
        vBackContentsBleed = cFOne;
        vBackContentsBleedAddition = cFZero;
    }
    
    vColor = lightingEquation(projectedPosition.xyz / projectedPosition.w, 
                              normalize(projectedNormal.xyz / projectedNormal.w));
    
    vTextureCoordinate[0] = aPageTextureCoordinate;
    vTextureCoordinate[1] = aContentsTextureCoordinate;
        
    gl_Position = uProjectionMatrix * projectedPosition;
}