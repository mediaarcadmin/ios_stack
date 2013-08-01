#include <stdio.h>
#include <stdlib.h>

//#include "drmmanager.h"


// From OTADLAClient.c
// Not including it because Windows-dependent elsewhere
/*******************************************************************************
 **
 ** Function:    PolicyCallback
 **
 ** Synopsis:    This function is called back by Bind during license policy evalu
 **              ation to process such things as OPLs, inclusion lists, and exten
 **              sible restrictions. To properly implement your own policy callback
 **              you must be careful of the compliance and robustness rules.
 **
 ** Arguments:
 **
 ** [f_pvPolicyCallbackData] -- Pointer to callback data in a format dependent on
 **                             the type of callback.
 ** [f_dwCallbackType]       -- The type of callback being made.
 ** [f_pv]                   -- Pointer to custom data, for OTADLA this will be NULL.
 **
 ** Returns:
 **                          DRM_SUCCESS  The function completed successfully.
 **
 *******************************************************************************/

/*
 DRM_RESULT DRM_CALL PolicyCallback(
								   IN const DRM_VOID *f_pvPolicyCallbackData,
								   IN DRM_POLICY_CALLBACK_TYPE f_dwCallbackType,
								   IN const DRM_VOID *f_pv );


#pragma comment( lib, "wininet.lib" )

#pragma warning ( disable: 6031 )
#pragma warning ( disable: 4101 ) //unreferenced local variable
#pragma warning ( disable: 4189 ) // local variable is initialized but not referenced 
#pragma warning ( disable: 4616 )
#pragma warning ( disable: 4102 )
 */

//DRM_CONST_STRING        g_dstrEncryptedFile = EMPTY_DRM_STRING;
//DRM_CONST_STRING        g_dstrDecryptedFile = EMPTY_DRM_STRING;
//DRM_MEDIA_FILE_CONTEXT *g_poMediaFile       = NULL;
//DRM_APP_CONTEXT        *g_pAppContext       = NULL;
//const DRM_CONST_STRING  g_dstrServiceId     = CREATE_DRM_STRING( L"{deb47f00-8a3b-416d-9b1e-5d55fd023044}" );
//const DRM_CONST_STRING  g_dstrAccountId     = CREATE_DRM_STRING( L"{3a87fb03-c53e-46f9-8cf8-9967cb6a1b14}" );


/* Name of the HDS file. */
#define HDS_STORE_FILE  L".\\playready.hds"
//#define HDS_STORE_FILE  L"./playready.hds"


#define MAX_COMMAND_LINE_SIZE       1024
#define MAX_DRM_APP_CONTEXT_SIZE    ( SIZEOF( DRM_APP_CONTEXT ) )
#define MAX_URL_SIZE                1024
#define MAX_HTTP_HEADER_SIZE        4096
#define MAX_HTTP_SERVER_NAME_LEN    50
#define MAX_HTTP_URL_LEN            100
#define MAX_CUSTOM_DATA_SIZE        1024

#define MAX_REDIRECTIONS_PER_REQUEST    5

/* HTTP status code of temporary redirection. */
#define HTTP_STATUS_TEMPORARY_REDIRECT  307

/*
** Server name (DNS name or IP address) of the server hosting the web services.
** It should be changed to reflect the actual server deployment.
*/
#define HTTP_SERVER_NAME                "playready.directtaps.net"
#define HTTP_SERVER_PORT                80

/*
** Virtual directories of the web services should be changed
** according to the actual server deployment.
*/
#define HTTP_WEB_SERVICE_ROOT           "/pr/svc/rightsmanager.asmx"


#define HTTP_HEADER_LICGET      "Content-Type: text/xml; charset=utf-8\r\nSOAPAction: \"http://schemas.microsoft.com/DRM/2007/03/protocols/AcquireLicense\"\r\n"

/*
#define HTTP_HEADER_LICACK      "Content-Type: text/xml; charset=utf-8\r\nSOAPAction: \"http://schemas.microsoft.com/DRM/2007/03/protocols/AcknowledgeLicense\"\r\n"
#define HTTP_HEADER_JOIN        "Content-Type: text/xml; charset=utf-8\r\nSOAPAction: \"http://schemas.microsoft.com/DRM/2007/03/protocols/JoinDomain\"\r\n"
#define HTTP_HEADER_LEAVE       "Content-Type: text/xml; charset=utf-8\r\nSOAPAction: \"http://schemas.microsoft.com/DRM/2007/03/protocols/LeaveDomain\"\r\n"
#define HTTP_HEADER_METERCERT   "Content-Type: text/xml; charset=utf-8\r\nSOAPAction: \"http://schemas.microsoft.com/DRM/2007/03/protocols/GetMeteringCertificate\"\r\n"
#define HTTP_HEADER_METERDATA   "Content-Type: text/xml; charset=utf-8\r\nSOAPAction: \"http://schemas.microsoft.com/DRM/2007/03/protocols/ProcessMeteringData\"\r\n"

#define HTTP_FALLBACK_SECURETIME_SERVER_NAME    "services.wmdrm.windowsmedia.com"
#define HTTP_FALLBACK_SECURETIME_PAGE           "/SecureClock/?Time"
#define HTTP_FALLBACK_SECURETIME_HEADER         "Content-Type: application/x-www-form-urlencoded\r\n"

#define HTTP_INITIATOR_ROOT             "/pr/initiator.aspx?p=0&contentid=ZVXWl75xFUOdCY/tO8bLCA==&type=license&content=http://playready.directtaps.net/pr/media/1044/Jazz_Audio_OPLs0.pya"
*/


