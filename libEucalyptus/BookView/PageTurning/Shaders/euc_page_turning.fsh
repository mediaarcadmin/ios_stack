precision highp float;

varying vec4 vColor;
varying vec2 vTextureCoordinate[2];

uniform sampler2D sPaperTexture;
uniform sampler2D sContentsTexture;

uniform bool uInvertContentsLuminance;
uniform bool uPaperIsDark;

uniform bool uDisableContentsTexture;

uniform float uBackContentsBleed;

// RGB/HSL conversion from http://blog.mouaif.org/2009/01/05/photoshop-math-with-glsl-shaders/

vec3 RGBToHSL(in vec3 color)
{
	vec3 hsl; // init to 0 to avoid warnings ? (and reverse if + remove first part)
	
	float fmin = min(min(color.r, color.g), color.b);    //Min. value of RGB
	float fmax = max(max(color.r, color.g), color.b);    //Max. value of RGB
	float delta = fmax - fmin;             //Delta RGB value

	hsl.z = (fmax + fmin) / 2.0; // Luminance

	if (delta == 0.0)		//This is a gray, no chroma...
	{
		hsl.x = 0.0;	// Hue
		hsl.y = 0.0;	// Saturation
	}
	else                                    //Chromatic data...
	{
		if (hsl.z < 0.5)
			hsl.y = delta / (fmax + fmin); // Saturation
		else
			hsl.y = delta / (2.0 - fmax - fmin); // Saturation
		
		float deltaR = (((fmax - color.r) / 6.0) + (delta / 2.0)) / delta;
		float deltaG = (((fmax - color.g) / 6.0) + (delta / 2.0)) / delta;
		float deltaB = (((fmax - color.b) / 6.0) + (delta / 2.0)) / delta;

		if (color.r == fmax )
			hsl.x = deltaB - deltaG; // Hue
		else if (color.g == fmax)
			hsl.x = (1.0 / 3.0) + deltaR - deltaB; // Hue
		else if (color.b == fmax)
			hsl.x = (2.0 / 3.0) + deltaG - deltaR; // Hue

		if (hsl.x < 0.0)
			hsl.x += 1.0; // Hue
		else if (hsl.x > 1.0)
			hsl.x -= 1.0; // Hue
	}

	return hsl;
}

float HueToRGB(in float f1, in float f2, in float hue)
{
	if (hue < 0.0)
		hue += 1.0;
	else if (hue > 1.0)
		hue -= 1.0;
	float res;
	if ((6.0 * hue) < 1.0)
		res = f1 + (f2 - f1) * 6.0 * hue;
	else if ((2.0 * hue) < 1.0)
		res = f2;
	else if ((3.0 * hue) < 2.0)
		res = f1 + (f2 - f1) * ((2.0 / 3.0) - hue) * 6.0;
	else
		res = f1;
	return res;
}

vec3 HSLToRGB(in vec3 hsl)
{
	vec3 rgb;
	
	if (hsl.y == 0.0)
		rgb = vec3(hsl.z, hsl.z, hsl.z); // Luminance
	else
	{
		float f2;
		
		if (hsl.z < 0.5)
			f2 = hsl.z * (1.0 + hsl.y);
		else
			f2 = (hsl.z + hsl.y) - (hsl.y * hsl.z);
			
		float f1 = 2.0 * hsl.z - f2;
		
		rgb.r = HueToRGB(f1, f2, hsl.x + (1.0/3.0));
		rgb.g = HueToRGB(f1, f2, hsl.x);
		rgb.b = HueToRGB(f1, f2, hsl.x - (1.0/3.0));
	}
	
	return rgb;
}

vec4 invertLuminance(in vec4 rgba)
{   
    vec3 hsl = RGBToHSL(rgba.rgb);
    hsl[2] = 1.0 - hsl[2];
    return vec4(HSLToRGB(hsl), rgba.a);
}

void main()
{
    vec4 paperColor = texture2D(sPaperTexture, vTextureCoordinate[0]);
    vec4 contentsColor;
    
    if(uDisableContentsTexture) {
        contentsColor = vec4(1.0);
    } else {
        contentsColor = texture2D(sContentsTexture, vTextureCoordinate[1]);
        if(gl_FrontFacing) {
        } else {
            contentsColor *= uBackContentsBleed;
            contentsColor += 1.0 - uBackContentsBleed;
        }
    }
    
    if(uInvertContentsLuminance) {       
        vec4 invertedPaperColor;
        if(uPaperIsDark) {
            invertedPaperColor = invertLuminance(paperColor);
        } else {
            invertedPaperColor = paperColor;
        }
        vec4 blendedInverted = invertedPaperColor * contentsColor;
        vec4 uninvertedBlended = invertLuminance(blendedInverted);
        gl_FragColor = vColor * uninvertedBlended;
    } else {
        gl_FragColor = vColor * paperColor * contentsColor;
    }
}