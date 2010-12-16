precision lowp float;

varying lowp vec3 vColor;
varying highp vec2 vPaperCoordinate;
varying highp vec2 vContentsCoordinate;
varying highp vec2 vZoomedContentsCoordinate;

uniform lowp sampler2D sPaperTexture;
uniform lowp sampler2D sContentsTexture;
uniform lowp sampler2D sZoomedContentsTexture;
uniform lowp sampler2D sHighlightTexture;
uniform lowp float uContentsBleed;

uniform bool uInvertContentsLuminance;

lowp vec3 invertLuminance(in lowp vec3 color)
{
    mediump float oldCombined = dot(color, vec3(0.299, 0.587, 0.114));
    mediump float scale =  (1.0 - oldCombined) / oldCombined;
    return min(color * scale, 1.0);
}

void main()
{
    lowp vec3 contentsColor = texture2D(sContentsTexture, vContentsCoordinate).rgb;
    lowp vec3 paperColor = texture2D(sPaperTexture, vPaperCoordinate).rgb;
    lowp vec3 highlightColor = texture2D(sHighlightTexture, vContentsCoordinate).rgb;
    lowp vec4 zoomedColor = texture2D(sZoomedContentsTexture, vZoomedContentsCoordinate);

    lowp float zoomedColorTransparency = 1.0 - zoomedColor.a;
    lowp float contentsBleedAddition = 1.0 - uContentsBleed;

    contentsColor = contentsColor * zoomedColorTransparency + zoomedColor.rgb;
    contentsColor = contentsColor * uContentsBleed + contentsBleedAddition;
    contentsColor = contentsColor * paperColor;

    if(uInvertContentsLuminance) {
        contentsColor = invertLuminance(contentsColor);
    }
   
    contentsColor = contentsColor * highlightColor;
    
    gl_FragColor = vec4(vColor * contentsColor, 1.0);
}