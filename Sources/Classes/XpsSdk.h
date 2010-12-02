/* ==========================================================================
	
	XpsSdk.h

	Application Programming Interface for Pagemark XPS Rendering.

	(c) Copyright 2008,2009,2010,2011 Pagemark Technology, Inc.
	All Rights Reserved Worldwide.

   ========================================================================== */
   
/** 
	@defgroup apifunc API Functions
	@defgroup callback Application Callbacks
	@defgroup data Data Structures
*/

/**
@mainpage Pagemark Rendering SDK Programming Interface

The Pagemark Rendering SDK is a multi-platform development kit that enables XPS document processing 
inside an application or enterprise workflow.

The API provides conversion from XPS to several image formats.  In addition, it allows users to modify the 
fixed page markup XML prior to rendering, allowing customized filtering of the page mark-up data.  
Access to document security features is also provided to support digital signatures.

The API is written in C and supports both Unicode and multi-byte character sets.  The API is provided in binary 
form as a static library or dynamic runtime library (if supported by the OS).


Here is a very simple example usage of the XPS SDK API to render an XPS document as a multi-page TIFF file:
@code
#include "XpsSdk.h"
int main(int argc, char **argv)
{
  int ok = -1;

  // Command line specifies input XPS file and output TIFF file
  if (argc >= 2)
  {
    static OutputFormat format = {OutputFormat_TIFF, 96, 96, 8, XPS_COLORSPACE_RGB, 1.0f, 1.0f, 1.0f, 0, 0, 0,
		{ImageCompression_LZW, 90}};

    ok = XPS_ConvertFile(argv[1], argv[2], 0, 0, 1000, &format) ? 0 : -1;
  }
  return ok;
}
@endcode

For detailed information please refer to the @ref apifunc "XPS Application Programming Interface"

*/

/** @page examples XPS Application Examples
	The Pagemark Technology XPS Rendering SDK includes a number of sample applications that
	will help demonstrate how to use the toolkit and serve as starter code for your own 
	applications.

	These examples are provided as Microsoft DevStudio 2005 projects that can be easily 
	compiled in that environment.

	<ul>
	  <li><b>SimpleViewer</b> - An MFC-based SDI application for viewing XPS documents.</li>
	  <li><b>XpsJpeg</b> - A console application for converting XPS document to JPEG files.</li>
	  <li><b>XpsPng</b> - A console application for converting XPS document to PNG files.</li>
	  <li><b>XpsTiff</b> - A console application for converting XPS document to TIFF files.</li>
	</ul>
 */

#ifndef _XPSSDK_H
#define _XPSSDK_H

#include "time.h"

#if defined(__APPLE__)
#  define XPSSDK __attribute__((visibility("default")))
#elif defined(_WIN32)
#  ifndef XPSSDK_STATIC
#     ifdef XPSSDK_EXPORTS
#       define XPSSDK	__declspec(dllexport)
#     else
#       define XPSSDK  __declspec(dllimport)
#     endif
#  else
#       define XPSSDK
#  endif
#else
#  define XPSSDK
#endif

#ifdef _WIN32
#  define XPSCALL	__cdecl
#else
#  define XPSCALL
#endif

/** @addtogroup data 
 *	@{
 */

#if defined __cplusplus
#define DEFAULT_VALUE(x)	 = x
extern "C" {
#else
#define DEFAULT_VALUE(x)
#endif

/** @brief XPS handle returned by XPS_Open
 */
typedef void * XPS_HANDLE;		///< used for various function calls.

/** @brief XPS handle returned by XPS_CreatePage 
*/
typedef void * XPS_PAGE_HANDLE;		///< used to add contents to a page

/** @brief XPS handle returned by XPS_OpenComponent
*/typedef void * XPS_COMPONENT_HANDLE;		///< used to read/add components to a container

/** @brief Character representation
 */
typedef char XPSCHAR;	///< used by XPS SDK


/** @brief Specifies the format of the rendered output.
 */
typedef enum 
{
	OutputFormat_BMP,		///< output to Windows bitmap file(s)
	OutputFormat_TIFF,		///< output to multi-page TIFF file
	OutputFormat_JPEG,		///< output to JPEG file(s)
	OutputFormat_PNG,		///< output to PNG file(s)
	OutputFormat_PCL6,		///< output to PCL6 printer
	OutputFormat_PDF,		///< output to rasterized PDF file
	OutputFormat_RAW,		///< output to raw raster data
} OutputFormatType;

/** @brief Specifies the compression method to be used for the TIFF and PDF output.
 */
typedef enum
{
	ImageCompression_NONE     = 1,	///< no compression
	ImageCompression_CCITTRLE = 2,	///< CCITT modified huffman RLE
	ImageCompression_CCITT3   = 3,	///< CCITT Group 3 fax (T.4)
	ImageCompression_CCITT4   = 4,	///< CCITT Gruop 4 fax (T.6)
	ImageCompression_LZW      = 5,	///< Lempel-Ziv & Welch
	ImageCompression_JPEG     = 7,	///< jpeg compression
	ImageCompression_PACKBITS = 32773,	///< zip pack bits
	ImageCompression_DEFLATE = 32946,	///< zip deflate
} ImageCompressionType;

/** @brief Specifies subsample type for JPEG output.
 */
typedef enum
{
	Subsample_None = 0x111111,	///< no subsampling (4:4:4)
	Subsample_422  = 0x211111,	///< subsample chrominance horizontally 2 to 1
	Subsample_422V = 0x121111,	///< subsample chrominance vertically 2 to 1
	Subsample_420  = 0x221111,	///< subsample chrominance 4 to 1
} SubsampleType;


/** @brief Coordinate transform matrix
 *
 * The transformation matrix is applied to coordinates in the following
 * fashion:
  \f[
	\left|\begin {array} {ccc}x&y&1\end {array}\right| 
	\otimes
	\left|\begin {array} {ccc}a&b\\c&d\\t_x&t_y\end {array}\right| 
	= \left|\begin {array} {ccc}ax+cy+t_x&bx+dy+t_y\end {array}\right|
  \f]
  */
typedef struct
{
	float a;	///< x scaling
	float b;	///< x rotation
	float c;	///< y rotation
	float d;	///< y scaling
	float tx;	///< x translation
	float ty;	///< y translation
} XPS_ctm;

/** @brief Rectangular area on fixed page.
  */
typedef struct
{
	float x;		///< x location of upper left corner (in 96dpi units).
	float y;		///< y location of upper left corner (in 96dpi units)
	float width;	///< width of rectangle (in 96dpi units).
	float height;	///< height of rectangle (in 96dpi units).
} XPSRECT;


/** @brief Values for colorSpace field in OutputFormat
*/
typedef enum { 
	XPS_COLORSPACE_RGB,			///< output is red/green/blue
	XPS_COLORSPACE_BGR,			///< output is blue/green/red
	XPS_COLORSPACE_ARGB,		///< output is alpha/red/green/blue
	XPS_COLORSPACE_BGRA,			///< output is blue/green/red/alpha
	XPS_COLORSPACE_RGBA		///< output is red/green/blue/alpha
} ColorSpaceFormat;

/** @brief JPEG output settings
*/
typedef struct
{
	unsigned		quality;		///< quality factor in range of 1 to 100
	SubsampleType	subsample;		///< see Subsample_XXX above
	int				progressive;	///< if true, use progress mode
} JPEGOptions;

/** @brief PNG output settings
*/
typedef struct
{
	int				interlace;		///< if true, use interlacing 
	int				dither;			///< if true, dither PNG output 
	int				dither_type;	///< index to dither type - zero is only valid value now
	unsigned char	*pTrc;			///< Pointer to Tonal Response Curve, if null - curve is linear
} PNGOptions;

/** @brief TIFF output settings
*/
typedef struct _TIFFOptions
{
	ImageCompressionType	compression;	///< type of compression to use
	unsigned				jpegQuality;	///< quality if using JPEG compression (0 to 100, higher numbers are better quality).
	unsigned char			*pTrc;			///< Pointer to Tonal Response Curve, if null - curve is linear
} TIFFOptions;

/** @brief PDF output settings
*/
typedef struct _PDFOptions
{
	ImageCompressionType	compression;	///< type of image compression to use for images stored in PDF
	// other parameters related to text and vector graphics TBD

} PDFOptions;

/** @brief Conversion specific options

	@see XPS_ConvertFile
*/
typedef union _ConvertOptions
{
	JPEGOptions	jpeg;	///< jpeg options (formatType = OutputFormat_JPEG)
	PNGOptions	png;	///< jpeg options (formatType = OutputFormat_PNG)
	TIFFOptions	tiff;	///< jpeg options (formatType = OutputFormat_TIFF)
	PDFOptions	pdf;	///< jpeg options (formatType = OutputFormat_PDF)
} ConvertOptions;

/** @brief Information on how to format rasterized output.

	This structure is passed to the conversion functions to indicate
	exactly how XPS documents and pages are to be rendered.

	@see XPS_Convert, XPS_ConvertFile, XPS_ConvertFpage
*/
typedef struct
{
	OutputFormatType formatType;	///< format to output rendered data in.
	unsigned xResolution;			///< horizontal resolution in DPI (e.g 96)
	unsigned yResolution;			///< vertical resolution in DPI (e.g. 96)
	unsigned colorDepth;			///< bits per pixel per plane (e.g. 8)
	ColorSpaceFormat colorSpace;	///< color space to use in rendering
	float	pagesizescale;			///< scales pagesize width and height (not content) by this amount
	float	pagesizescalewidth;		///< scales pagesize width (not content) by this amount
	float	pagesizescaleheight;	///< scales pagesize height (not content) by this amount
	XPS_ctm *ctm;					///< optional transform matrix to be applied to all coordinates.
	int		forceTextAntiAliasOff;	///< when set to non-zero text rendering will not be anti-aliased.
	void *	iccProfile;				///< optional ICC profile to be applied (can be a buffer or filename).
	ConvertOptions options;			///< conversion specific options.
} OutputFormat;


/** @brief Digital signing status
*/
typedef enum {
	SignatureMissing,		///< content is not signed.
	SignatureValid,			///< signed content is valid and unmodified since signing.
	SignatureIncompliant,	///< required compnents are not properly signed.
	SignatureBroken,		///< signed content has been modified since signing.
	SignatureQuestionable	///< signature can not be validated.
} DigtialSignatureStatus;

/** @brief Signing certificate information
*/
typedef struct _DigitalCertificateProperties
{
	XPSCHAR * owner;		///< certificate owner name.
	XPSCHAR * issuer;		///< certificate issuing authority.
	XPSCHAR * validAfter;	///< valid start date (in UTC format).
	XPSCHAR * validBefore;	///< expiration date (in UTC format).
} DigitalCertificateProperties;

/** @brief Digital signature settings.
*/
typedef struct _DigitalSignatureProperties
{
	XPSCHAR *			signerName;		///< signer's name.
	XPSCHAR *			uuid;			///< unique signature uuid.
	XPSCHAR *			signDate;		///< signing date.
} DigitalSignatureProperties;

/** @brief Page signing location structure.
*/
typedef struct _PageSpot {
	float x;					///< x location to place sign request.
	float y;					///< y location to place sign request.
} PageSpot;

/** @brief Digital signing request settings.
*/
typedef struct _DigitalSignatureRequest
{
	XPSCHAR * signerName;		///< requested signer's name.
	XPSCHAR * intent;			///< signing intent (may be NULL).
	XPSCHAR * location;			///< location signed (may be NULL).
	XPSCHAR * signBy;			///< requested sign by date (in UTC format).
	XPSCHAR * pageUri;			///< page to display signing request on.
	XPSCHAR * uuid;				///< unique signature request uuid.
	PageSpot  spot;				///< location on page to place signing request.
	DigitalSignatureProperties * pSignature;	///< link to signature if request has been honored (NULL otherwise).
} DigitalSignatureRequest;

/** @brief Core document properties
*/
typedef struct
{
	XPSCHAR * title;			///< document title
	XPSCHAR * author;			///< document author
	XPSCHAR * subject;			///< document subject
	XPSCHAR * description;		///< document description
	XPSCHAR * keywords;			///< document keyword list
	XPSCHAR * category;			///< document category
	XPSCHAR * createdate;		///< document creation date
	XPSCHAR * modifydate;		///< document modification date
	XPSCHAR * printdate;		///< document print date
	XPSCHAR * status;			///< document release status
	XPSCHAR * type;				///< document type
	XPSCHAR * identifier;		///< document unique identifier
	XPSCHAR * version;			///< document version
	XPSCHAR * revision;			///< document revision
	XPSCHAR * language;			///< document language
	XPSCHAR * modifier;			///< document modifier name
} CoreProperties;

/** @brief Fixed page size information
*/
typedef struct
{
	float width;		///< fixed page width in 96dpi units
	float height;		///< fixed page height 96dpi units
	struct
	{
		float x;		///< content box horizontal offset in 96dpi units
		float y;		///< content box vertical offset in 96dpi units
		float width;	///< content box width in 96dpi units
		float height;	///< content box height in 96dpi units
	} contentBox;		///< page content box information
} FixedPageProperties;

/** @brief Detailed raster information
*/
typedef struct
{
	void *		pBits;			///< pointer to the raster data
	unsigned	widthInPixels;	///< width in pixels
	unsigned	height;			///< height in rows
	unsigned	rowStride;		///< row size in bytes
	unsigned	bytesPerPixel;	///< pixel size in bytes
} RasterImageInfo;

/** @brief Available anti-aliasing modes
*/
typedef enum {
	XPS_ANTIALIAS_OFF,	///< anti-aliasing off
	XPS_ANTIALIAS_ON	///< anti-aliasing on
} XPS_ANTIALIAS_MODE;

/** @brief data stream seek modes
*/
typedef enum {
	XPS_SEEK_START,		///< seek from start
	XPS_SEEK_CURRENT,	///< seek from current
	XPS_SEEK_END		///< seek from end
} XPS_SEEK_RELATIVE;

/** @brief Document outline information
*/
typedef struct {
	XPSCHAR *	text;			///< outline text description
	XPSCHAR *   targetUri;		///< target uri
	int			page;			///< page index (if internal)
	XPSRECT		location;		///< target location on page (if internal)
} DocumentOutline;

/** @brief List of URI entries
*/
typedef struct {
	int			count;			///< number of entries
	const XPSCHAR *	uri[1];	///< list of component URIs.
} UriList;

/** @brief File within Zip package info
*/
typedef struct {

	int compression_type; ///< compression type 8 = deflate, 0 = uncompressed
	int length;				///< number of bytes of compressed data
	int uncmp_length;
	void *pComponentData;	///< pointer to data for this component
} XPS_FILE_PACKAGE_INFO;

/** @brief Document contents information
*/
typedef UriList DocumentContents;

/** @brief Document contents information
*/
typedef UriList PageResources;

/** @brief Unique ID
*/
#define XPS_URI_SOURCE_PLUGIN	(0x1001)	///< ID indicating that this is a URI stream plugin.

/** @brief Unique ID
*/
#define XPS_DATA_OUPUT_PLUGIN	(0x1002)	///< ID indicating that this is a data output stream plugin.

/** @brief Plugin-specific handle 
 */
typedef void * URI_HANDLE;		///< passed to URI related callbacks

/** @brief Plugin-specific handle 
 */
typedef void * DATAOUT_HANDLE;		///< passed to data output related callbacks

/*@}*/		// data

/** @addtogroup callback 
 *	@{
 */
/** @brief Progress callback
 *
 * This function is registered by calling XPS_RegisterProgressCallback and
 * is called periodically as the document is rendered.
 *
 * @param[in] userdata caller specific data provided to XPS_SetUserData.
 * @param[in] pagePercentComplete percentage of page rendered (0 to 100).
 * @param[in] numPagesRenderedSoFar number of pages rendered.
 * @param[in] totalPages number of pages to be rendered.
 * @see XPS_RegisterProgressCallback
*/
typedef void (XPSCALL *XpsProgressCallback)(
		void *userdata, 
		unsigned pagePercentComplete, 
		unsigned numPagesRenderedSoFar, 
		unsigned totalPages
		);

/** @brief XML callback
 *
 * This functions is registered by calling XPS_RegisterXpsCallback and is called
 * as each buffer of fpage XML is being processed.  Applications can use this to
 * filter out XML tags or to inject their own XML.
 *
 * Note that any modifications made to the XML will only affect the rendered image,
 * the original XPS document will not be modified.
 *
 * @param[in] userdata caller specific data provided to XPS_SetUserData.
 * @param[in] xmlIn buffer containing XML data.
 * @param[in] sizeIn number of characters in smlIn.
 * @param[out] xmlOut pointer to receive address of output XML data.
 * @param[out] sizeOut number of characters in xmlOut.
 * @see XPS_RegisterXpsCallback
*/
typedef void (XPSCALL *XpsCallback)(
		void *userdata, 
		const char *xmlIn, 
		size_t sizeIn, 
		char **xmlOut,			//$Review: who owns/frees this buffer?
		size_t *sizeOut
		);

/** @brief Error callback
 *
 * This functions is registered by calling XPS_RegisterErrorCallback and is
 * called when an error is detected in the fpage XML.
 *
 * @param[in] userdata caller specific data provided to XPS_SetUserData.
 * @param[in] errorMsg string specifying error information.
 * @see XPS_RegisterErrorCallback
*/
typedef void (XPSCALL *XpsErrorCallback)(
		void *userdata, 
		const char *errorMsg		//$Review: need to address localization issues.
		);

/** @brief Called at start of rendering a page
 *
 * This function is registered with XPS_RegisterPageBeginCallback and is called
 * at the start of each page being rendered.
 *
 * @param[in] userdata caller specific data provided to XPS_SetUserData.
 * @param[in] nPage number of page about to be rendered.
 * @return true if page should be processed, false will skip rendering of the
 * page.
 * @see XPS_RegisterPageBeginCallback, XpsRenderCompleteCallback
*/
typedef int (XPSCALL *XpsRenderBeginCallback)(
		void *userdata,
		int nPage
		);

/** @brief Called when rendering is complete
 *
 * This function is registered with XPS_RegisterPageCompleteCallback and is called
 * at the end of each page being rendered.
 *
 * @param[in] userdata caller specific data provided to XPS_SetUserData.
 * @param[in] data is a pointer to information regarding the rendered data (e.g., the surface bits).  The
 * caller is responsible for releasing the memory by calling XPS_ReleaseImageMemory with data->pBits.
 * @see XPS_RegisterPageCompleteCallback, XPS_ReleaseImageMemory, XpsRenderBeginCallback
 */
typedef void (XPSCALL *XpsRenderCompleteCallback)(
		void *userdata, 
		RasterImageInfo *data
		);

/** @brief Signing callback
 *
 * This functions is registered by calling XPS_RegisterSigningCallback and is called
 * as each resource is validated against the signing digest.
 *
 * @param[in] userdata caller specific data provided to XPS_SetUserData.
 * @param[in] urlPath resource being validated.
 * @param[in] location bounding rectangle of resource on page.
 * @param[in] pSig signing information.
 * @param[in] status results of signature verification.
 * @return zero if the client wishes to cancel further validation on this page.  
 * Otherwise, return non-zero to continue.
 * @see XPS_RegisterSigningCallback, XPS_SetUserData.
*/
typedef int (XPSCALL *XpsSigningCallback)(
		void *							userdata, 
	    const char *					uriPath,
		XPSRECT							location,
		DigitalSignatureProperties *	pSig,
		DigtialSignatureStatus			status
		);

/** @brief URI open callback.

	This callback is registered as part of the XPS_URI_PLUGIN_INFO structure
	passed to the XPS_ConvertFpage function.  It is called whenever resource
	data (including the fpage XML) is needed.

	@param pszUri[in] specifies URI being requested.
	@param userdata user specific instance data specified in convert call
	@return handle to be used in future calls, or NULL if plug-in cannot
	handle this URI.
	@see XPS_ConvertFpage, PFN_URI_CLOSE
 */
typedef URI_HANDLE (XPSCALL * PFN_URI_OPENA)(
		const char * pszUri,
		void * userdata
		);

/** @brief URI open callback.

	This callback is registered as part of the XPS_URI_PLUGIN_INFO structure
	passed to the XPS_ConvertFpage function.  It is called whenever resource
	data (including the fpage XML) is needed.

	@param pszUri specifies URI being requested.
	@param userdata user specific instance data specified in convert call
	@return[in] handle to be used in future calls, or NULL if plug-in cannot
	handle this URI.
	@see XPS_ConvertFpage
 */
typedef URI_HANDLE (XPSCALL * PFN_URI_OPENW)(
		const wchar_t * pszUri,
		void * userdata
		);

/** @brief URI rewind callback.

	This callback is registered as part of the XPS_URI_PLUGIN_INFO structure
	passed to the XPS_ConvertFpage function.  It is called whenever resource
	data is to be reset to the start.

	@param[in] h handle that was returned by open call.
	@see XPS_ConvertFpage
 */
typedef void (XPSCALL * PFN_URI_REWIND)(
		URI_HANDLE h
		);

/** @brief URI skip callback.

	This callback is registered as part of the XPS_URI_PLUGIN_INFO structure
	passed to the XPS_ConvertFpage function.  It is called whenever resource
	data is to be skipped over.

	@param[in] h handle that was returned by open call.
	@param[in] nBytes number of bytes to skip in URI stream.
	@return actual number of bytes skipped.
	@see XPS_ConvertFpage
 */
typedef size_t (XPSCALL * PFN_URI_SKIP)(
			URI_HANDLE h, 
			size_t nBytes
			);

/** @brief URI read callback.

	This callback is registered as part of the XPS_URI_PLUGIN_INFO structure
	passed to the XPS_ConvertFpage function.  It is called whenever resource
	data is to be read.

	@param[in] h handle that was returned by open call.
	@param[out] pBuff pointer to buffer to receive URI data.
	@param[in] nBytes number of bytes to read.
	@return actual number of bytes read.
	@see XPS_ConvertFpage
 */
typedef size_t (XPSCALL * PFN_URI_READ)(
			URI_HANDLE h, 
			unsigned char * pBuff, 
			size_t nBytes
			);

/** @brief URI get size callback.

	This callback is registered as part of the XPS_URI_PLUGIN_INFO structure
	passed to the XPS_ConvertFpage function.  It is called to query the size
	of the resource data.

	@param[in] h handle that was returned by open call.
	@return total number of bytes in stream.
	@see XPS_ConvertFpage
 */
typedef size_t (XPSCALL * PFN_URI_SIZE)(
			URI_HANDLE h
			);

/** @brief URI close callback.

	This callback is registered as part of the XPS_URI_PLUGIN_INFO structure
	passed to the XPS_ConvertFpage function.  It is called whenever resource
	data processing is complete.

	@param[in] h handle that was returned by open call.
	@see XPS_ConvertFpage, PFN_URI_OPENA, PFN_URI_OPENW
 */
typedef void (XPSCALL * PFN_URI_CLOSE)(
			URI_HANDLE h
			);


/** @brief Output stream open callback.

	This callback is registered as part of the XPS_DATAOUT_PLUGIN_INFO structure
	passed to the XPS_ConvertFpage function.  It is called whenever ouput
	data needs to be written.

	@param psz[in] specifies name of output entity (file).
	@param userdata user specific instance data specified in convert call
	@return handle to be used in future calls, or NULL if plug-in cannot
	handle this data stream.
	@see XPS_ConvertFpage, PFN_DATAOUT_CLOSE
 */
typedef DATAOUT_HANDLE (XPSCALL * PFN_DATAOUT_OPENA)(
		const char * psz,
		void * userdata
		);

/** @brief Output stream open callback.

	This callback is registered as part of the XPS_DATAOUT_PLUGIN_INFO structure
	passed to the XPS_ConvertFpage function.  It is called whenever ouput
	data needs to be written.

	@param psz[in] specifies name of output entity (file).
	@param userdata user specific instance data specified in convert call
	@return handle to be used in future calls, or NULL if plug-in cannot
	handle this data stream.
	@see XPS_ConvertFpage, PFN_DATAOUT_CLOSE
 */
typedef DATAOUT_HANDLE (XPSCALL * PFN_DATAOUT_OPENW)(
		const wchar_t * psz,
		void * userdata
		);

/** @brief Data output stream seek callback.

	This callback is registered as part of the XPS_DATAOUT_PLUGIN_INFO structure
	passed to the XPS_ConvertFpage function.  It is called whenever the output
	position needs to be adfjusted.

	@param[in] h handle that was returned by open call.
	@param[in] nPos new position.
	@param[in] eRel relative to where.
	@return new position or -1 if unsuccessful.
	@see XPS_ConvertFpage
 */
typedef size_t (XPSCALL * PFN_DATAOUT_SEEK)(
			DATAOUT_HANDLE h, 
			size_t nPos,
			XPS_SEEK_RELATIVE eRel
			);

/** @brief data stream write callback.

	This callback is registered as part of the XPS_DATAOUT_PLUGIN_INFO structure
	passed to the XPS_ConvertFpage function.  It is called whenever output
	data needs to be written.

	@param[in] h handle that was returned by open call.
	@param[out] pBuff pointer to buffer of output data.
	@param[in] nBytes number of bytes to write.
	@return actual number of bytes written.
	@see XPS_ConvertFpage
 */
typedef size_t (XPSCALL * PFN_DATAOUT_WRITE)(
			DATAOUT_HANDLE h, 
			unsigned char * pBuff, 
			size_t nBytes
			);

/** @brief get current position of output data stream.

	This callback is registered as part of the XPS_DATAOUT_PLUGIN_INFO structure
	passed to the XPS_ConvertFpage function.  It is called to query the current
	position of the output stream.

	@param[in] h handle that was returned by open call.
	@return current byte position in stream.
	@see XPS_ConvertFpage
 */
typedef size_t (XPSCALL * PFN_DATAOUT_POS)(
			DATAOUT_HANDLE h
			);

/** @brief output data stream close callback.

	This callback is registered as part of the XPS_DATAOUT_PLUGIN_INFO structure
	passed to the XPS_ConvertFpage function.  It is called whenever data output
	is complete.

	@param[in] h handle that was returned by open call.
	@see XPS_ConvertFpage, PFN_DATAOUT_OPENA, PFN_DATAOUT_OPENW
 */
typedef void (XPSCALL * PFN_DATAOUT_CLOSE)(
			DATAOUT_HANDLE h
			);

/*@}*/		// callback


/** @brief Set of function callbacks for registering a URI source plugin.
 *	@ingroup data
 */
typedef struct _XPS_URI_PLUGIN_INFO {
	unsigned short	idType;			///< plugin type must be XPS_URI_SOURCE_PLUGIN
	unsigned short	cbSize;			///< sizeof (XPS_URI_PLUGIN_INFO).
	char			guid[40];		///< globally unique id.
	void *			userdata;		///< instance data passed to open calls.
	PFN_URI_OPENA	pfnOpenA;		///< function to call to open a URI
	PFN_URI_OPENW	pfnOpenW;		///< function to open a wide-char URI.
	PFN_URI_REWIND	pfnRewind;		///< function to call to reset to start of stream
	PFN_URI_SKIP	pfnSkip;		///< function to call to skip n bytes of data.
	PFN_URI_READ	pfnRead;		///< function to call to read next n bytes into a buffer.
	PFN_URI_SIZE	pfnSize;		///< function to call to get total byte count in stream.
	PFN_URI_CLOSE	pfnClose;		///< function to call to close URI
} XPS_URI_PLUGIN_INFO;

/** @brief Set of function callbacks for registering a data output plugin.
 *	@ingroup data
 */
typedef struct _XPS_DATAOUT_PLUGIN_INFO {
	unsigned short	idType;			///< plugin type must be XPS_DATA_OUTPUT_PLUGIN
	unsigned short	cbSize;			///< sizeof (XPS_DATAOUT_PLUGIN_INFO).
	char			guid[40];		///< globally unique id.
	void *			userdata;		///< instance data passed to open calls.
	PFN_DATAOUT_OPENA	pfnOpenA;		///< function to call to open a URI
	PFN_DATAOUT_OPENW	pfnOpenW;		///< function to open a wide-char URI.
	PFN_DATAOUT_SEEK	pfnSeek;		///< function to call to skip n bytes of data.
	PFN_DATAOUT_WRITE	pfnWrite;		///< function to call to read next n bytes into a buffer.
	PFN_DATAOUT_POS		pfnPos;		///< function to call to get total byte count in stream.
	PFN_DATAOUT_CLOSE	pfnClose;		///< function to call to close URI
} XPS_DATAOUT_PLUGIN_INFO;

/** @addtogroup apifunc 
 *	@{
 */

/**
 * @brief Initialize XPS Renderer
 *
 * Prepares rendering engine for operations.  Client applications
 * should call this function prior to making any other API calls.
 *
 * @see XPS_End
 */
XPSSDK void XPSCALL XPS_Start(void);


/**
 * @brief Uninitialize XPS Renderer
 *
 * Cleans up rendering engine at completion.  Client applications
 * should call this function prior to exiting.
 *
 * If more than one call to XPS_Start was made, then a corresponding number
 * of calls to XPS_End should be made.
 * 
 * @see XPS_Start
 */
XPSSDK void XPSCALL XPS_End(void);

/**
 * @brief Open XPS document for rendering
 *
 * Opens a XPS document in preparation for rendering or querying information.
 *
 * @param[in] xpsFile name of XPS file
 * @param[in] tmpPath optional temporary path to use for unzipping
 * @returns handle to be used in subsequent XPS API calls
 * @see XPS_Close
 */
XPSSDK XPS_HANDLE XPSCALL XPS_Open(const XPSCHAR * xpsFile, const XPSCHAR * tmpPath DEFAULT_VALUE(0));

/**
 * @brief Open XPS document for rendering
 *
 * Opens a XPS document in preparation for rendering or querying information.
 *
 * @param[in] xpsFile name of XPS file
 * @param[in] tmpPath optional temporary path to use for unzipping
 * &param[in] password optional password to be used when unzipping
 * @returns handle to be used in subsequent XPS API calls
 * @see XPS_Close
 */
XPSSDK XPS_HANDLE XPSCALL XPS_OpenWithPassword(const XPSCHAR * xpsFile, const XPSCHAR * tmpPath DEFAULT_VALUE(0) , const XPSCHAR * password DEFAULT_VALUE(0));

#if __cplusplus
/**
 * @brief Open XPS document for rendering
 *
 * Opens a XPS document in preparation for rendering or querying information.
 *
 * @param[in] pUri pointer to stream input class to provide contents of xps document.
 * @param[in] tmpPath optional temporary path to use for unzipping
 * @returns handle to be used in subsequent XPS API calls
 * @see XPS_Close
 */
XPSSDK XPS_HANDLE XPSCALL XPS_Open2( class XGE_UriSource *pUri, const XPSCHAR * tmpPath DEFAULT_VALUE(0));

/**
 * @brief Open XPS document for rendering
 *
 * Opens a XPS document in preparation for rendering or querying information.
 *
 * @param[in] pUri pointer to stream input class to provide contents of xps document.
 * @param[in] tmpPath optional temporary path to use for unzipping
 * &param[in] password optional password to be used when unzipping
 * @returns handle to be used in subsequent XPS API calls
 * @see XPS_Close
 */
XPSSDK XPS_HANDLE XPSCALL XPS_Open2WithPassword( class XGE_UriSource *pUri, const XPSCHAR * tmpPath DEFAULT_VALUE(0) , const XPSCHAR * password DEFAULT_VALUE(0));
#endif

/**
 * @brief Open XPS document for rendering
 *
 * Opens a XPS document stored in memory in preparation for rendering or querying information.
 *
 * @param[in] buff point to contents of XPS file buffer
 * @param[in] len size of XPS file buffer
 * &param[in] password optional password to be used when unzipping
 * @returns handle to be used in subsequent XPS API calls
 * @see XPS_Close
 */
XPSSDK XPS_HANDLE XPSCALL XPS_OpenFromMemory(void * buff, size_t len, const XPSCHAR * password DEFAULT_VALUE(0));

/**
 * @brief Close XPS handle
 *
 * Closes a XPS document when processing is complete.
 *
 * @param[in] handle value returned from XPS_Open
 * @returns none
 * @see XPS_Open
 */
XPSSDK void XPSCALL XPS_Close(XPS_HANDLE handle);

/**
 * @brief Convert pages of an XPS document to a given format
 *
 * Converts the specified pages from an XPS document to the image format specified by the format structure.  
 *
 * @param[in] handle handle returned from XPS_Open
 * @param[in] destinationFile character string containing name of destination file.
 * The destinationFile string may contain a printf style argument such as %d 
 * for the page number. For example, "myfile_page%d.jpg". This is useful when
 * converting documents to a raster image format that supports only one page
 * image per file such as JPEG. 
 * @param[in] documentIndex index of which document to convert (0 is first document).
 * @param[in] fromPage the first page to start conversion from (0 is first page).
 * @param[in] numPages number of sequential pages to convert, starting from fromPage.
 * @param[in] format pointer to structure containing output format options.
 * @returns true if successful; false otherwise
 * @see XPS_Open, XPS_Cancel, XPS_RegisterProgressCallback
 */  
XPSSDK int XPSCALL XPS_Convert(XPS_HANDLE handle, const XPSCHAR * destinationFile, int documentIndex, unsigned fromPage, unsigned numPages, const OutputFormat *format);

/**
 * @brief Convert pages of an XPS document to a given format
 *
 * Converts the specified pages from an XPS document to the image format specified by the format structure.  
 *
 * This is the simpliest single call conversion API, but does not provide support for cancelation
 * or progress reporting.
 *
 * @param[in] xpsFile character string containing name of XPS file.
 * @param[in] destinationFile character string containing name of destination file.
 * The destinationFile string may contain a printf style argument such as %d 
 * for the page number. For example, "myfile_page%d.jpg". This is useful when
 * converting documents to a raster image format that supports only one page
 * image per file such as JPEG. 
 * @param[in] documentIndex index of which document to convert (0 is first document).
 * @param[in] fromPage the first page to start conversion from (0 is first page).
 * @param[in] numPages number of sequential pages to convert, starting from fromPage.
 * @param[in] format pointer to structure containing output format options.
 * @returns true if successful; false otherwise
 * @see XPS_Convert
 */  
XPSSDK int XPSCALL XPS_ConvertFile(const XPSCHAR *xpsFile, const XPSCHAR *destinationFile, int documentIndex, unsigned fromPage, unsigned numPages, const OutputFormat *format);

/**
 * @brief Convert an XPS Fpage to a given format
 *
 * Converts the XML page to the image format specified by the format structure.  The caller is responsible
 * for providing all page and resource data to the rendering engine.
 *
 * @param[in] fpageFile character string containing name of input fpage.  This will be passed to open function 
 * specified by the caller in the pUriInfo structure.
 * @param[in] destinationFile character string containing name of destination file.
 * @param[in] pUriInfo pointer to structure that provides callbacks to get fpage and other
 * resource contents (if NULL standard file I/O will be used).
 * @param[in] pDataOutInfo pointer to structure that provides callbacks to write output data streams
 * (if NULL standard file I/O will be used).
 * @param[in] format pointer to structure containing output format options.
 * @returns true if successful; false otherwise
 * @see XPS_RegisterProgressCallback
 */  
XPSSDK int XPSCALL XPS_ConvertFpage(const XPSCHAR * fpageFile, const XPSCHAR * destinationFile, XPS_URI_PLUGIN_INFO *pUriInfo, XPS_DATAOUT_PLUGIN_INFO *pDataOutInfo, const OutputFormat *format);

/**
 * @brief Cancel an in-progress XPS document conversion 
 * @param[in] handle value returned from XPS_Open
 */  
XPSSDK void XPSCALL XPS_Cancel(XPS_HANDLE handle);

/**
 * @brief Set directory path of location to use for writing temporary files
 * extracted from the XPS document. 
 *
 * If not specified, the renderer will attempt to determine the most appropriate
 * location for the current platform.
 *
 * @param path specifies which disk folder to use for creation of temporary
 * files during rendering process.
 * @returns true if successful; false if unable to create directory
 */
XPSSDK int XPSCALL XPS_SetTempDirectory(const XPSCHAR * path);

/**
 * @brief Set directory path of location that contains the ICC sRGB and SWOP
 * Profiles. 
 * @param[in] path specifies path to ICC profiles.
 * @returns true if successful; false if unable to create directory
 */
XPSSDK int XPSCALL XPS_SetICCColorDirectory(const XPSCHAR * path);


/**
 * @brief Set user data for callbacks
 *
 * @param[in] handle instance handle returned by XPS_Open
 * @param[in] userdata user supplied argument passed as first parameter to 
 * registered callback functions
 * @returns none
 */
XPSSDK void XPSCALL XPS_SetUserData(XPS_HANDLE handle, void *userdata);

/**
 * @brief Register a callback function to monitor progress of Convert
 *
 * @param[in] handle instance handle returned by XPS_Open
 * @param[in] callback pointer to function to call with updates
 * @returns none
 */
XPSSDK void XPSCALL XPS_RegisterProgressCallback(XPS_HANDLE handle, XpsProgressCallback callback);

/**
 * @brief Register a callback function to filter fixed page XML data
 *
 * Register a callback function to receive and optionally modify XPS fixed page XML data.  
 * The callback receives a buffer of XML data as input. The callback function processes the 
 * data as desired, which may include adding or removing XML and/or resources.  A pointer to 
 * the processed XML data and its size is passed back through the xmlOut parameter.  If the callback 
 * functions acts only as an observer without modifying the XML data, it must still pass back a pointer 
 * to the unmodified XML data.
 *
 * Note that when resources are added, the URI resource pathing is normally relative, and where it is 
 * relative to depends on whether the path starts with /.  An absolute path may be specified by 
 * prepending the path with the drive letter.    
 * 
 * To summarize:
 *
 * \li <i>pathA/pathB/resource</i> :	The resource is relative to the location of the fpage file in the XPS 
 * document tree.  For a typical document, this is <i>temp_dir/Documents/1/Pages</i> where <i>temp_dir</i> is 
 * the temporary path set by XPS_SetTempDirectory, so the resulting path is <i>temp_dir/Documents/1/Pages/pathA/pathB/resource</i>.  
 * Unless the structure of the XPS document is known, this method should not be used as results may be inconsistent.
 * \li <i>/pathA/pathB/resource</i> :	The resource is relative to the root directory of the unzipped document, which is 
 * the temporary path set by XPS_SetTempDirectory.  The resulting path is <i>temp_dir/pathA/pathB/resource</i>.
 *	\li <i>C:/pathA/pathB/resource</i> :	The resource is in an absolute path on users disk.  
 *
 * @param[in] handle instance handle returned by XPS_Open
 * @param[in] callback pointer to function to call 
 * @returns none
 */
//$ToDo: The concept of drive letter is Windows specific!  Need a platform agnostic solution.
XPSSDK void XPSCALL XPS_RegisterXpsCallback(XPS_HANDLE handle, XpsCallback callback);

/**
 * @brief Register a callback function to receive error notification
 *
 * @param[in] handle instance handle returned by XPS_Open
 * @param[in] callback pointer to function to call 
 * @returns none
 */
XPSSDK void XPSCALL XPS_RegisterErrorCallback(XPS_HANDLE handle, XpsErrorCallback callback);

/**
 * @brief Register a callback function to be called at start of page rendering
 *
 * @param[in] handle instance handle returned by XPS_Open
 * @param[in] callback pointer to function to call
 * @see XPS_RegisterPageCompleteCallback
 */
XPSSDK void XPSCALL XPS_RegisterPageBeginCallback(XPS_HANDLE handle, XpsRenderBeginCallback callback);

/**
 * @brief Register a callback function to be called at end of page rendering
 *
 * @param[in] handle instance handle returned by XPS_Open
 * @param[in] callback pointer to function to call
 * @see XPS_RegisterPageBeginCallback, XPS_ReleaseImageMemory
 */
XPSSDK void XPSCALL XPS_RegisterPageCompleteCallback(XPS_HANDLE handle, XpsRenderCompleteCallback callback);

/**
 * @brief Register a callback function to receive signing status.
 *
 * As a fixed page is rendered, the various resources will be checked for
 * signing information (if any) and the callback will be made to indicate
 * the status of each signed resource.
 *
 * @param[in] handle instance handle returned by XPS_Open
 * @param[in] callback pointer to function to call 
 * @returns none
 * @see XPS_SetUserData
 */
XPSSDK void XPSCALL XPS_RegisterSigningCallback(XPS_HANDLE handle, XpsSigningCallback callback);

/**
 * @brief Save XPS file
 *
 * @param[in] handle value returned from XPS_Open
 * @param[in] xpsSaveFile name of file to save as
 * @return true if successfully saved.
 */
XPSSDK int XPSCALL XPS_Save(XPS_HANDLE handle, const char *xpsSaveFile); 

/**
 * @brief Save XPS file
 *
 * @param[in] handle value returned from XPS_Open
 * @param[in] xpsSaveFile name of file to save as
 * &param[in] password optional password to be used when zipping
 * @return true if successfully saved.
 */
XPSSDK int XPSCALL XPS_SaveWithPassword(XPS_HANDLE handle, const char *xpsSaveFile,  const char * password DEFAULT_VALUE(0)); 

/**
 * @brief Remove a document from the package
 *
 * @warning NOT YET IMPLEMENTED IN SDK
 *
 * @param[in] handle value returned from XPS_Open.
 * @param[in] documentIndex which document to remove (0 is first document).
 */
XPSSDK void XPSCALL XPS_RemoveDocument(XPS_HANDLE handle, int documentIndex);

/**
 * @brief Remove pages 
 *
 * @param[in] handle value returned from XPS_Open
 * @param[in] documentIndex which document to remove pages from
 * @param[in] fromPage first page to remove
 * @param[in] numPages number of pages to remove
 * @returns number of pages removed
 */
XPSSDK int XPSCALL XPS_RemovePages(XPS_HANDLE handle, int documentIndex, unsigned fromPage, unsigned numPages);

/**
 * @brief Insert pages 
 *
 * @param[in] hDest handle for XPS document to insert into
 * @param[in] docDest which document to insert pages into
 * @param[in] afterPage where to insert new pages (-1 = before first page, 0 =  after first page, etc.)
 * @param[in] hSrc handle for XPS document to insert into
 * @param[in] docSrc which document to insert from
 * @returns number of pages inserted
 */
XPSSDK int XPSCALL XPS_InsertPages(XPS_HANDLE hDest, int docDest, int afterPage, XPS_HANDLE hSrc, int docSrc);

/**
 * @brief Create fixed page 
 *
 * Creates a new fixed page within an XPS document.
 *
 * @param[in] handle value returned from XPS_Open
 * @param[in] documentIndex which document to add page to
 * @param[in] afterPage index to insert page after (0=make page first)
 * @param[in] pageName name of page to be added (if NULL, a name will be automatically generated).
 * @returns handle to page to be used for adding contents to page.
 * @see XPS_WritePageXml, XPS_CopyPage, XPS_ClosePage
 */
XPSSDK XPS_PAGE_HANDLE XPSCALL XPS_CreatePage(XPS_HANDLE handle, int documentIndex, int afterPage, const XPSCHAR *pageName);

/**
 * @brief Write XML data to new page 
 *
 * Contents will be appended to contents of page.  Data can be written using
 * a series of sequential calls to this function.
 *
 * @warning NOT YET IMPLEMENTED IN SDK
 *
 * @param[in] hPageDest value returned from XPS_CreatePage
 * @param[in] xml null terminated xml string to be written to page.
 * @returns number of characters written to page.
 * @see XPS_CreatePage
 */
XPSSDK int XPSCALL XPS_WritePageXml(XPS_PAGE_HANDLE hPageDest, XPSCHAR * xml);

/**
 * @brief Copy an existing page to new page 
 *
 * A page and all its resources will be copied to the new page.  The pages
 * need not be contained in the same XPS document.
 *
 * The following example demontrates how a page can be copied from one
 * document to another:
 * @code
 *	XPS_Start();
 *	XPS_HANDLE hXpsSrc = XPS_Open(filenameSrc);
 *	XPS_HANDLE hXpsDest = XPS_Open(filenameDest);
 *
 *	XPS_PAGE_HANDLE hPage = XPS_CreatePage(hXpsDest, 0, 1, "/Documents/1/Pages/new_01.fpage");
 *	XPS_CopyPage(hPage, XPS_GetPage(hXpsSrc, 0, 1));
 *
 *	XPS_ClosePage(hPage);
 *	XPS_Close(hXpsSrc);
 *	XPS_Close(hXpsDest);
 *	XPS_End();
 * @endcode
 *
 * @param[in] hPageDest handle of new page returned from XPS_CreatePage
 * @param[in] hPageSrc handle of source page returned from XPS_GetPage
 * @returns non-zero if successful.
 * @see XPS_CreatePage, XPS_GetPage
 */
XPSSDK int XPSCALL XPS_CopyPage(XPS_PAGE_HANDLE hPageDest, XPS_PAGE_HANDLE hPageSrc);

/**
 * @brief Close a new page 
 *
 * Completes creation of a new page in an XPS document.
 *
 * @param[in] hPage handle of new page returned from XPS_CreatePage
 * @see XPS_CreatePage, XPS_GetPage
 */
XPSSDK void XPSCALL XPS_ClosePage(XPS_PAGE_HANDLE hPage);

/**
 * @brief Get fixed page pointer
 *
 * Provides a handle to an existing fixed page to be used for copying the
 * contents to a new page, or for adding additional resources.
 *
 * @param[in] handle value returned from XPS_Open
 * @param[in] documentIndex which document (0=first)
 * @param[in] pageIndex index to page to retrieve handle (0=first)
 * @returns handle to page to be used for adding contents to page (or NULL if no
 * such page).
 * @see XPS_CopyPage, XPS_AddPageResource, XPS_GetPageResources, XPS_GetPageUri, XPS_ClosePage
 */
XPSSDK XPS_PAGE_HANDLE XPSCALL XPS_GetPage(XPS_HANDLE handle, int documentIndex, int pageIndex);

/**
 * @brief Get URI location of page
 *
 * @param[in] hPage handle of page returned from XPS_CreatePage or XPS_GetPage
 * @returns URI page location within XPS container.
 * @see XPS_GetPage, XPS_CreatePage
 */
XPSSDK const XPSCHAR * XPSCALL XPS_GetPageUri(XPS_PAGE_HANDLE hPage);

/**
 * @brief Get a list of contents in an XPS document 
 *
 * Caller must free the information with XPS_FreeContents
 *
 * @param[in] handle XPS document handle returned by XPS_Open
 * @returns pointer to content information.
 * @see XPS_Open, XPS_FreeContents, XPS_OpenComponent
 */
XPSSDK DocumentContents * XPSCALL XPS_GetContents(XPS_HANDLE handle);

/**
 * @brief Release list of contents in an XPS container 
 *
 * @param[in] contents pointer to information returned by XPS_GetContents
 * @see XPS_GetContents
 */
XPSSDK void XPSCALL XPS_FreeContents(DocumentContents * contents);

/**
 * @brief Open a component within an XPS document for direct reading or writing.
 *
 * If component does not exist and it is specified as writeable, a new component will
 * be created and added to the XPS container.
 * 
 * @param[in] handle XPS document handle returned by XPS_Open
 * @param[in] uri URI location of component to be opened.
 * @param[in] isWriteable true if component will be written to.
 * @returns handle to component to be used in read, write and close calls.
 * @see XPS_Open, XPS_GetContents, XPS_CloseComponent, XPS_ReadComponent, XPS_WriteComponent
 */
XPSSDK XPS_COMPONENT_HANDLE XPSCALL XPS_OpenComponent(XPS_HANDLE handle, XPSCHAR * uri, int isWriteable);

/**
 * @brief Read data from a component within an XPS document.
 *
 * The following example shows how a component can be read:
 * @code
 *	XPS_Start();
 *	XPS_HANDLE hXps = XPS_Open(filename);
 *
 *	XPS_COMPONENT_HANDLE hComp = XPS_OpenComponent(hXps, "Documents/1/Pages/1.fpage", false);
 *	unsigned char buff[4096];
 *	while (XPS_ReadComponent(hComp, buff, sizeof(buff)) == sizeof(buff)) {
 *		:
 *	}
 *	XPS_CloseComponent(hComp);
 *	XPS_Close(hXps);
 *	XPS_End();
 * @endcode
 *
 * @param[in] handle component handle to component returned by XPS_OpenComponent
 * @param[in] buff buffer to receive contents (if NULL, the data will be skipped).
 * @param[in] len number of bytes to read (if buff and len are zero input is rewound).
 * @returns number of bytes successfully read.
 * @see XPS_OpenComponent
 */
XPSSDK int XPSCALL XPS_ReadComponent(XPS_COMPONENT_HANDLE handle, void * buff, int len);

/**
 * @brief Write data to a component within an XPS document.
 *
 * The following example shows how a component can be written:
 * @code
 *	XPS_Start();
 *	XPS_HANDLE hXps = XPS_Open(filename);
 *
 *	XPS_COMPONENT_HANDLE hComp = XPS_OpenComponent(hXps, "Documents/1/Pages/1.fpage", true);
 *	char buff[] = "<?xml version=\"1.0\" encoding=\"utf-8\"?><FixedPage Width="816" Height="1056"></FixedPage>";
 *	XPS_WriteComponent(hComp, buff, sizeof(buff));
 *
 *	XPS_CloseComponent(hComp);
 *	XPS_Close(hXps);
 *	XPS_End();
 * @endcode 
 *
 * @param[in] handle component handle to component returned by XPS_OpenComponent
 * @param[in] buff buffer to write to component.
 * @param[in] len number of bytes to write.
 * @returns number of bytes successfully written.
 * @see XPS_OpenComponent
 */
XPSSDK int XPSCALL XPS_WriteComponent(XPS_COMPONENT_HANDLE handle, void * buff, int len);

/**
 * @brief Close a component.
 *
 * @param[in] handle component handle to component returned by XPS_OpenComponent
 * @see XPS_OpenComponent
 */
XPSSDK void XPSCALL XPS_CloseComponent(XPS_COMPONENT_HANDLE handle);

/**
 * @brief Add a resource URI to list of page dependancies.
 *
 * The following example shows how a resource can be added:
 * @code
 *	XPS_Start();
 *	XPS_HANDLE hXps = XPS_Open(filename);
 *
 *	XPS_COMPONENT_HANDLE hComp = XPS_OpenComponent(hXps, "Documents/1/Resources/watermark.jpg", true);
 *	XPS_WriteComponent(hComp, jpegdata, sizeof(jpegdata));
 *	XPS_AddPageResource(XPS_GetPage(hXps, 0, 1), "Documents/1/Resources/watermark.jpg");
 *
 *	XPS_CloseComponent(hComp);
 *	XPS_Close(hXps);
 *	XPS_End();
 * @endcode
 *
 * @param[in] hPage handle of page returned from XPS_CreatePage or XPS_GetPage
 * @param[in] resourceUri URI location of resource with XPS package
 * @returns non-zero if successful.
 * @see XPS_GetPage, XPS_CreatePage
 */
XPSSDK int XPSCALL XPS_AddPageResource(XPS_PAGE_HANDLE hPage, const XPSCHAR * resourceUri);

/**
 * @brief Remove a resource URI from list of page dependancies.
 *
 * @warning NOT YET IMPLEMENTED IN SDK
 *
 * @param[in] hPage handle of page returned from XPS_CreatePage or XPS_GetPage
 * @param[in] resourceUri URI location of resource with XPS package
 * @returns non-zero if successful.
 * @see XPS_GetPage, XPS_CreatePage
 */
XPSSDK int XPSCALL XPS_RemovePageResource(XPS_PAGE_HANDLE hPage, const XPSCHAR * resourceUri);

/**
 * @brief Get a list of page resources.
 *
 * Caller must free the list by calling XPS_FreeResources.
 *
 * @param[in] handle page handle returned by XPS_GetPage
 * @returns pointer to list of resources used be page.
 * @see XPS_GetPage, XPS_FreeResources
 */
XPSSDK PageResources * XPSCALL XPS_GetPageResources(XPS_PAGE_HANDLE handle);

/**
 * @brief Release list of page resources.
 *
 * @param[in] resources pointer returned by XPS_GetPageResources.
 * @see XPS_GetPageResources
 */
XPSSDK void XPSCALL XPS_FreeResources(PageResources * resources);

/**
 * @brief Get thumbnail image file from XPS document
 *
 * @param[in] handle handle returned from XPS_Open
 * @param[in] thumbnailFile buffer to store thumbnail image file name
 * @param[in] maxchars maximum number of character that can be stored in thumbnailFile
 * @returns true if successful; false if thumbnail not available
 */
XPSSDK int XPSCALL XPS_GetThumbnail(XPS_HANDLE handle, XPSCHAR * thumbnailFile, size_t maxchars);

/**
 * @brief Get number of documents in XPS document package
 * @param[in] handle handle returned from XPS_Open
 * @returns number of documents found
 */
XPSSDK unsigned XPSCALL XPS_GetNumberDocuments(XPS_HANDLE handle);

/**
 * @brief Get number of pages in XPS document package
 * @param[in] handle handle returned from XPS_Open
 * @param[in] documentIndex 0-based index specififying which document. 
 * if set to -1, the total number of pages in all documents is returned.
 * @returns number of pages
 */
XPSSDK unsigned XPSCALL XPS_GetNumberPages(XPS_HANDLE handle, int documentIndex);

/**
 * @brief Get XPS document package properties
 * @param[in] handle handle returned from XPS_Open
 * @returns pointer to core propterties.  Caller must release structure by calling 
 * XPS_FreeCoreProperties.
 * @see XPS_FreeCoreProperties
 */
XPSSDK CoreProperties * XPSCALL XPS_GetCoreProperties(XPS_HANDLE handle);

/**
 * @brief Set XPS document package properties.
 *
 * Any existing properties will be replaced with the new values.
 *
 * @warning NOT YET IMPLEMENTED IN SDK
 *
 * @param[in] handle handle returned from XPS_Open
 * @param[in] properties pointer to a CoreProperties structure with values to set.
 * @returns true if properties successfully set.
 * @see XPS_GetCoreProperties
 */
XPSSDK int XPSCALL XPS_SetCoreProperties(XPS_HANDLE handle, CoreProperties *properties);

/**
 * @brief Free CoreProperties structure returned by XPS_GetCoreProperties
 *
 * @param[in] properties pointer to a CoreProperties structure returned by XPS_GetCoreProperties
 * @returns none
 * @see XPS_GetCoreProperties
 */
XPSSDK void XPSCALL XPS_FreeCoreProperties(CoreProperties *properties);

/**
 * @brief Get XPS digital signature properties
 *
 * Contents may be signed by more than one signer.  The returned signature information will
 * be a list of signature information.  The end of list is indicated by NULL values for all fields.
 *
 * @param[in] handle handle returned from XPS_Open
 * @param[in] documentIndex index of document (0=first)
 * @returns pointer to digital signature information. Caller must release this structure by 
 * calling XPS_FreeSignatureProperties.
 * @see XPS_FreeSignatureProperties
 */
XPSSDK DigitalSignatureProperties * XPSCALL XPS_GetSignatureProperties(XPS_HANDLE handle, int documentIndex);

/**
 * @brief Free DigitalSignatureProperties structure returned by XPS_GetSignatureProperties
 *
 * @param[in] properties pointer to a DigitalSignatureProperties structure
 * @returns none
 * @see XPS_GetSignatureProperties
 */
XPSSDK void XPSCALL XPS_FreeSignatureProperties(DigitalSignatureProperties *properties);

/**
 * @brief Get XPS digital signature request
 *
 * More than one request may be present.  The returned information will
 * be a list where the end of list is indicated by NULL values for all fields.
 *
 * @param[in] handle handle returned from XPS_Open
 * @param[in] documentIndex document index (0 = first)
 * @returns pointer to digital signature information. Caller must release this structure by 
 * calling XPS_FreeSignatureRequestProperties.  If there are no pending signature requests, a
 * NULL value will be returned.
 * @see XPS_FreeSignatureRequestProperties
 */
XPSSDK DigitalSignatureRequest * XPSCALL XPS_GetSignatureRequestProperties(XPS_HANDLE handle, int documentIndex);

/**
 * @brief Free DigitalSignatureRequest structure returned by XPS_GetSignatureRequestProperties
 *
 * @param[in] properties pointer to a DigitalSignatureRequest structure
 * @returns none
 * @see XPS_GetSignatureRequestProperties
 */
XPSSDK void XPSCALL XPS_FreeSignatureRequestProperties(DigitalSignatureRequest *properties);

/**
 * @brief Digitally sign fixed pages within a document.
 *
 * A digest will be calculated for all resources on the given page(s) and the user will be 
 * presented with a platform specific interface for selecting their private
 * signing key.
 *
 * @param[in] handle returned from XPS_Open
 * @param[in] uuid pointer to unique id (the uuid should match the
 * original signature request if this signing is to satisfy a request).
 * @param[in] documentIndex index of document (0=first)
 * @param[in] fromPage index of first page to sign (0=first)
 * @param[in] numPages number of pages to sign (-1=sign to last page)
 * @param[in] allowBreaking if true don't fail if signing will break other signed content.
 * @param[in] hCert platform specific certificate handle (if NULL, user may be prompted).
 * @returns true if document successfully signed.
 * @see XPS_VerifySignedFixedPages, XPS_AddSignatureRequest
 */
XPSSDK int XPSCALL XPS_SignFixedPages(XPS_HANDLE handle, XPSCHAR * uuid, int documentIndex, int fromPage, int numPages, int allowBreaking, void * hCert);

/**
 * @brief Verify that a signature is valid.
 *
 * If a callback has been registered through XPS_RegisterSigningCallback, then
 * the caller can get information on which resources have signing issues.
 *
 * @param[in] handle returned from XPS_Open
 * @param[in] uuid id of signer to verify.
 * @param[in] documentIndex index of document (0=first)
 * @param[in] fromPage index of first page to verify (0=first)
 * @param[in] numPages number of pages to verify (-1=to last page)
 * @returns status of signature.
 * @see XPS_SignFixedPages, XPS_RegisterSigningCallback
 */
XPSSDK DigtialSignatureStatus XPSCALL XPS_VerifySignedFixedPages(XPS_HANDLE handle, XPSCHAR * uuid, int documentIndex, int fromPage, int numPages);

/**
 * @brief Get platform specific certificate of signer.
 *
 * @param[in] handle returned from XPS_Open
 * @param[in] uuid id of signer to get certificate.
 * @param[in] documentIndex index of document (0=first)
 * @returns pointer to platform specific signature.
 * @see XPS_GetSignatureProperties
 */
XPSSDK void * XPSCALL XPS_GetSignerCertificate(XPS_HANDLE handle, XPSCHAR * uuid, int documentIndex);

/**
 * @brief Add a signature request to the document.
 *
 * @param[in] handle returned from XPS_Open
 * @param[in] documentIndex index of document (0=first, -1=all)
 * @param[in] pRequest information on signing request.
 * @returns true if signing request successfully added.
 * @see XPS_SignFixedPages, XPS_GenerateUUID
 */
XPSSDK int XPSCALL XPS_AddSignatureRequest(XPS_HANDLE handle, int documentIndex, DigitalSignatureRequest * pRequest);

/**
 * @brief Get FixedPage properties
 *
 * @param[in] handle handle returned from XPS_Open
 * @param[in] documentIndex index of document (0 = first)
 * @param[in] page the page for which to retrieve Fixed Page properties for (0 = first)
 * @param[out] properties pointer to FixedPageProperties
 * @return true if successful; false if not
 */
XPSSDK int XPSCALL XPS_GetFixedPageProperties(XPS_HANDLE handle, int documentIndex, int page, FixedPageProperties *properties);

/**
 * @brief Release image memory
 *
 * @param[in] pBits pointer to raster data provided in the XpsRenderCompleteCallback
 * @note
 * Ownership of the raster image data buffer transfers to the client in 
 * XpsRenderCompleteCallback.  This allows clients to make use of the image 
 * data as long as needed, without the need to make a copy of it.
 * Clients are subsequently responsible for freeing the buffer when it is no
 * longer needed. Failure to call this to free the buffer will result in huge 
 * memory leaks.
 * @see XPS_RegisterPageCompleteCallback, XpsRenderCompleteCallback
 */
XPSSDK void XPSCALL XPS_ReleaseImageMemory(void *pBits);

/**
 * @brief Turn on or off anti-aliasing in rendering.
 *
 * @param[in] handle instance handle returned by XPS_Open
 * @param[in] mode indicates whether to turn on or off ant-aliasing
 * (XPS_ANTIALIAS_ON or XPS_ANTIALIAS_OFF respectively).
 * @see XPS_GetAntiAliasMode
 */
XPSSDK void XPSCALL XPS_SetAntiAliasMode(XPS_HANDLE handle, XPS_ANTIALIAS_MODE mode);

/**
 * @brief Check if anti-aliasing is enabled for rendering.
 *
 * @param[in] handle instance handle returned by XPS_Open
 * @return XPS_ANTIALIAS_ON if anti-aliasing is enabled, otherwise
 * XPS_ANTIALIAS_OFF.
 * @see XPS_SetAntiAliasMode
 */
XPSSDK XPS_ANTIALIAS_MODE XPSCALL XPS_GetAntiAliasMode(XPS_HANDLE handle);

/**
 * @brief Get version string of XPS Sdk.
 *
 * @return pointer to version string (e.g. "1.0.0.42")
 */
XPSSDK const XPSCHAR * XPSCALL XPS_GetVersionString(void);

/**
 * @brief Get disk location of temporary page source xml file.
 *
 * If the page has not yet been rendered, it may not be possible to
 * determine the page location, so this function should be called after
 * XPS_Convert.
 *
 * @param[in] handle value returned from XPS_Open
 * @param[in] documentIndex which document (0 = first)
 * @param[in] pageIndex which page (0 = first)
 * @return pointer to path (e.g. "C:\Windows\Temp\xge\Documents\1\Pages\1.fpage") or NULL if 
 * unable to determine.  Caller must release memory by calling XPS_FreePageSourcePath.
 * @see XPS_FreePageSourcePath
 */
XPSSDK const XPSCHAR * XPSCALL XPS_GetPageSourcePath(XPS_HANDLE handle, int documentIndex, int pageIndex);

/**
 * @brief Free disk location of temporary page source xml file.
 *
 * @param[in] pszPath pointer to path returned by XPS_GetPageSourcePath.
 * @see XPS_GetPageSourcePath
 */
XPSSDK void XPSCALL XPS_FreePageSourcePath(const XPSCHAR * pszPath);

/**
 * @brief Get disk location of temporary document directory.
 *
 * @param[in] handle value returned from XPS_Open
 * @param[in] documentIndex which document (0 = first)
 * @return pointer to path (e.g. "C:\Windows\Temp\xge\Documents\1") or NULL if 
 * unable to determine.  Caller must release memory by calling XPS_FreeDocumentPath.
 * @see XPS_FreeDocumentPath
 */
XPSSDK const XPSCHAR * XPSCALL XPS_GetDocumentPath(XPS_HANDLE handle, int documentIndex);

/**
 * @brief Free disk location of temporary document directory.
 *
 * @param[in] pszPath pointer to path returned by XPS_GetDocumentPath.
 * @see XPS_GetDocumentPath
 */
XPSSDK void XPSCALL XPS_FreeDocumentPath(const XPSCHAR * pszPath);

/**
 * @brief Get document outline information.
 *
 * The information is returned as a list of outline entries
 * and corresponding target information.  The final entry is indicated
 * by a NULL value in all fields.
 *
 * @warning NOT YET IMPLEMENTED IN SDK
 *
 * @param[in] handle value returned from XPS_Open
 * @param[in] documentIndex which document (0 = first)
 * @returns document outline information (caller should call XPS_FreeDocumentOutline
 * to release).
 * @see XPS_FreeDocumentOutline
 */
XPSSDK DocumentOutline * XPSCALL XPS_GetDocumentOutline(XPS_HANDLE handle, int documentIndex);

/**
 * @brief Release document outline information.
 *
 * @warning NOT YET IMPLEMENTED IN SDK
 *
 * @param[in] outlineInfo document outline information from XPS_GetDocumentOutline.
 * @see XPS_GetDocumentOutline
 */
XPSSDK void XPSCALL XPS_FreeDocumentOutline(DocumentOutline * outlineInfo);

/**
 * @brief Generate a unique identifier (UUID)
 *
 * This function generates a random identifer.  It is not guarenteed to be
 * globally unique (but the odds are good).
 *
 * Caller must release the UUID by calling XPS_FreeUUID.
 *
 * @param[in] fDashes true indicates that UUID should be returned with
 * embedded dashes (eg. CA987434-AA49-4FCB-B745-B16ADC179B05), otherwise
 * no dashes are added (eg. CA987434AA494FCBB745B16ADC179B05).
 * @see XPS_FreeUUID
 */
XPSSDK const XPSCHAR * XPSCALL XPS_GenerateUUID(int fDashes);

/**
 * @brief Release UUID.
 *
 * @param[in] uuid identifer  generated by XPS_GenerateUUID.
 * @see XPS_GetDocumentOutline
 */
XPSSDK void XPSCALL XPS_FreeUUID(const XPSCHAR * uuid);

/**
 * @brief Set a named option setting
 *
 * Options persist until XPS_Close is called.
 *
 * @param[in] handle XPS handle returned by XPS_Open
 * @param[in] option name of option (case sensitive)
 * @param[in] value value to set option to
 * @see XPS_QueryOption
 *
 */
XPSSDK void XPSCALL XPS_SetOption(XPS_HANDLE handle, const XPSCHAR * option, int value, char *aValue);

/**
 * @brief Delete a named option setting
 *
 * @param[in] handle XPS handle returned by XPS_Open
 * @param[in] option name of option (case sensitive)
 * @see XPS_SetOption
 *
 */
XPSSDK void XPSCALL XPS_DeleteOption(XPS_HANDLE handle, const XPSCHAR * option);

/**
 * @brief Query a named option setting
 *
 * @param[in] handle XPS handle returned by XPS_Open
 * @param[in] option name of option (case sensitive)
 * @param[out] value current option value (can be NULL if just checking for option existence)
 * @return true if option was found.
 * @see XPS_SetOption
 *
 */
XPSSDK int XPSCALL XPS_QueryOption(XPS_HANDLE handle, const XPSCHAR * option, int * value);

XPSSDK int  XPS_inflate(void * v, int f);
XPSSDK int  XPS_inflateInit(void * v);
XPSSDK int  XPS_inflateInit2(void * v,int wb);
XPSSDK int XPS_inflateEnd(void * v);	

	
XPSSDK int XPSCALL XPS_GetComponentInfo(XPS_HANDLE handle, XPSCHAR * uri, XPS_FILE_PACKAGE_INFO *pFilePackageInfo);

XPSSDK int XPSCALL XPS_GetPackageDir(XPS_HANDLE handle,void **p);
XPSSDK int XPSCALL XPS_RegisterDrmHandler(XPS_HANDLE handle, XPS_URI_PLUGIN_INFO *pUriInfo);
/*@}*/		// apifunc

#if defined __cplusplus
}
#endif // __cplusplus


#endif
