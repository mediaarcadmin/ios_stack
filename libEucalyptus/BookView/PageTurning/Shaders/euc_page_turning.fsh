precision mediump float;

varying lowp vec4 vColor;
varying highp vec2 vPaperCoordinate;
varying highp vec2 vContentsCoordinate;

uniform lowp sampler2D sPaperTexture;
uniform lowp sampler2D sContentsTexture;
uniform lowp float uContentsBleed;

uniform bool uInvertContentsLuminance;

lowp vec4 invertLuminance(in mediump vec4 rgba)
{   
    mediump float oldCombined = dot(rgba.rgb, vec3(0.299, 0.587, 0.114));
    return vec4(min(rgba.rgb * ((1.0 - oldCombined) / oldCombined), 1.0), rgba.a);
}

void main()
{
    lowp vec4 paperColor = texture2D(sPaperTexture, vPaperCoordinate);
    lowp vec4 contentsColor = texture2D(sContentsTexture, vContentsCoordinate);
    
    contentsColor = mix(vec4(1.0), contentsColor, uContentsBleed);

    if(uInvertContentsLuminance) {       
        gl_FragColor = vColor * invertLuminance(paperColor * contentsColor);
    } else {
        gl_FragColor = vColor * paperColor * contentsColor;
    }
}