precision mediump float;

varying lowp vec4 vColor;
varying highp vec2 vPaperCoordinate;
varying highp vec2 vContentsCoordinate;
varying highp vec2 vZoomedContentsCoordinate;

uniform lowp sampler2D sPaperTexture;
uniform lowp sampler2D sContentsTexture;
uniform lowp sampler2D sZoomedContentsTexture;
uniform lowp sampler2D sHighlightTexture;
uniform lowp float uContentsBleed;

uniform bool uInvertContentsLuminance;

lowp vec4 invertLuminance(in mediump vec4 rgba)
{   
    mediump float oldCombined = dot(rgba.rgb, vec3(0.299, 0.587, 0.114));
    return vec4(min(rgba.rgb * ((1.0 - oldCombined) / oldCombined), 1.0), rgba.a);
}

void main()
{
    lowp vec4 zoomedColor = texture2D(sZoomedContentsTexture, vZoomedContentsCoordinate);
    lowp vec4 contentsColor = texture2D(sContentsTexture, vContentsCoordinate);
    lowp vec4 paperColor = texture2D(sPaperTexture, vPaperCoordinate);

    //lowp float zoomedColorTransparency = 1.0 - zoomedColor.a;
    //contentsColor =  contentsColor * zoomedColorTransparency + zoomedColor;
    
    contentsColor =  mix(contentsColor, zoomedColor,  zoomedColor.a);

    lowp vec4 highlightColor = texture2D(sHighlightTexture, vContentsCoordinate);
    
    //contentsColor =  mix(vec4(1.0), ((contentsColor * (1.0 - highlightColor.a)) + highlightColor), uContentsBleed);
    contentsColor =  mix(vec4(1.0), mix(contentsColor, highlightColor, highlightColor.a), uContentsBleed);
    
    if(uInvertContentsLuminance) {       
        gl_FragColor = vColor * invertLuminance(paperColor * contentsColor);
    } else {
        gl_FragColor = vColor * paperColor * contentsColor;
    }
}