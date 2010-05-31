/**@@@+++@@@@******************************************************************
**
** Microsoft PlayReady
** Copyright (c) Microsoft Corporation. All rights reserved.
**
***@@@---@@@@******************************************************************
*/

#ifndef __DRMMETER_CERT_PUBLIC_KEY_H__
#define __DRMMETER_CERT_PUBLIC_KEY_H__

ENTER_PK_NAMESPACE;

const PUBKEY g_pubkeyMeteringCertVerify =
{
    TWO_BYTES(0xAE, 0xF2), TWO_BYTES(0x91, 0xD5), TWO_BYTES(0xDA, 0xBE), TWO_BYTES(0x13, 0x37), 
    TWO_BYTES(0x46, 0x0F), TWO_BYTES(0xC3, 0x43), TWO_BYTES(0xD8, 0x88), TWO_BYTES(0x64, 0x9F), 
    TWO_BYTES(0x43, 0x8F), TWO_BYTES(0x12, 0x85), TWO_BYTES(0x99, 0x64), TWO_BYTES(0xA0, 0xB0), 
    TWO_BYTES(0x82, 0x27), TWO_BYTES(0x69, 0xED), TWO_BYTES(0x8E, 0x52), TWO_BYTES(0x1D, 0x1F), 
    TWO_BYTES(0x8D, 0x14), TWO_BYTES(0x92, 0x5A), TWO_BYTES(0xCD, 0xD3), TWO_BYTES(0xD6, 0x7C)
};

const PUBKEY g_pubkeyRootMeteringCert = /* "pub" */
{
    TWO_BYTES(0x45, 0xB1), TWO_BYTES(0xA7, 0xE1), TWO_BYTES(0x90, 0x81), TWO_BYTES(0x98, 0x37), 
    TWO_BYTES(0x00, 0xCC), TWO_BYTES(0x89, 0xA7), TWO_BYTES(0x57, 0x24), TWO_BYTES(0x72, 0xB9), 
    TWO_BYTES(0xC1, 0x29), TWO_BYTES(0xA3, 0x62), TWO_BYTES(0xD9, 0x55), TWO_BYTES(0x74, 0x04), 
    TWO_BYTES(0x02, 0x7D), TWO_BYTES(0x6E, 0x69), TWO_BYTES(0x79, 0xE9), TWO_BYTES(0x6A, 0xD9), 
    TWO_BYTES(0x7A, 0x92), TWO_BYTES(0xE4, 0xF3), TWO_BYTES(0x4B, 0x6B), TWO_BYTES(0x42, 0x6C)
};

EXIT_PK_NAMESPACE;

#endif /* __DRMMETER_CERT_PUBLIC_KEY_H__ */
