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

const lowp vec4 cWhite = vec4(1.0);

const float cFZero = 0.0;
const float cFOne = 1.0;

lowp vec4 invertLuminance(in mediump vec4 rgba)
{   
    mediump float oldCombined = dot(rgba.rgb, vec3(0.299, 0.587, 0.114));
    return vec4(min(rgba.rgb * ((cFOne - oldCombined) / oldCombined), cFOne), rgba.a);
}

void main()
{
    lowp vec4 paperColor = texture2D(sPaperTexture, vPaperCoordinate);

    lowp vec4 zoomedContentsColor = texture2D(sZoomedContentsTexture, vZoomedContentsCoordinate);
    lowp vec4 contentsColor = mix(texture2D(sContentsTexture, vContentsCoordinate), 
                                  zoomedContentsColor,
                                  zoomedContentsColor.a);
                                      
    lowp vec4 highlightColor = texture2D(sHighlightTexture, vContentsCoordinate);



    contentsColor = mix(cWhite, contentsColor * (cFOne - highlightColor.a) + highlightColor, uContentsBleed);
    
    if(uInvertContentsLuminance) {       
        gl_FragColor = vColor * invertLuminance(paperColor * contentsColor);
    } else {
        gl_FragColor = vColor * paperColor * contentsColor;
    }
}