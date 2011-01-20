/* libwapcaplet-CFString.m
 *
 * String internment and management tools, converted to be backed with 
 * Apple's CoreFoundation CFStrings, and made thread-safe.
 *
 * Copyright 2011 Things Made Out Of Other Things.
 */

#import <CoreFoundation/CoreFoundation.h>

#define lwc_string_s __CFString const

#import "libwapcaplet/libwapcaplet.h"
#import <pthread.h>

static CFMutableBagRef sContext;
static pthread_once_t sContextOnceControl = PTHREAD_ONCE_INIT;
static pthread_mutex_t sContextMutex = PTHREAD_MUTEX_INITIALIZER;

static void CreateContext()
{
    sContext = CFBagCreateMutable(kCFAllocatorDefault, 0, &kCFTypeBagCallBacks);
}

static inline CFMutableBagRef checkOutContext()
{
    pthread_once(&sContextOnceControl, CreateContext);
    pthread_mutex_lock(&sContextMutex);
    return sContext;
}

static inline void checkInContext()
{
    pthread_mutex_unlock(&sContextMutex);
}

static CFMutableDictionaryRef sUTF8Map;
static pthread_once_t sUTF8MapOnceControl = PTHREAD_ONCE_INIT;
static pthread_mutex_t sUTF8MapMutex = PTHREAD_MUTEX_INITIALIZER;

static void CreateUTF8Map()
{
    sUTF8Map = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
}

static inline CFMutableDictionaryRef checkOutUTF8Map()
{
    pthread_once(&sUTF8MapOnceControl, CreateUTF8Map);
    pthread_mutex_lock(&sUTF8MapMutex);
    return sUTF8Map;
}

static inline void checkInUTF8Map()
{
    pthread_mutex_unlock(&sUTF8MapMutex);
}


lwc_string * lwc_intern_cf_string(CFStringRef str)
{
    CFMutableBagRef context = checkOutContext();
    CFBagAddValue(context, str);
    CFStringRef ret = CFBagGetValue(context, str);
    checkInContext();
    return ret;
}

lwc_error lwc_intern_string(const char *s, size_t slen, lwc_string **ret)
{
    CFStringRef value = CFStringCreateWithBytes(kCFAllocatorDefault, (UInt8*)s, slen, kCFStringEncodingUTF8, false);
    *ret = lwc_intern_cf_string(value);
    CFRelease(value);
    return lwc_error_ok;
}

lwc_error lwc_intern_substring(lwc_string *str, size_t ssoffset, size_t sslen, lwc_string **ret)
{   
    CFStringRef value = CFStringCreateWithSubstring(kCFAllocatorDefault, str, CFRangeMake(ssoffset, sslen));
    *ret = lwc_intern_cf_string(value);
    CFRelease(value);
    return lwc_error_ok;
}

lwc_string *lwc_string_ref(lwc_string *str)
{
    CFMutableBagRef context = checkOutContext();
    CFBagAddValue(context, str);
    //NSCParameterAssert(str == CFBagGetValue(context, str));
    checkInContext();
    return str;
}

void lwc_string_unref(lwc_string *str)
{
    CFMutableBagRef context = checkOutContext();
    if(CFBagGetCountOfValue(context, str) == 1) {
        CFMutableDictionaryRef UTF8Map = checkOutUTF8Map();
        CFDictionaryRemoveValue(UTF8Map, str);
        checkInUTF8Map();
    }
    CFBagRemoveValue(context, str);
    checkInContext();
}

lwc_error lwc_string_caseless_isequal(lwc_string *str1, lwc_string *str2, bool *ret)
{
    *ret = ((str1 == str2) || (CFStringCompare(str1, str2, kCFCompareCaseInsensitive) == kCFCompareEqualTo));
    return lwc_error_ok;
}

static CFDataRef _lwc_str_UTF8Data(lwc_string *str)
{
    CFMutableDictionaryRef UTF8Map = checkOutUTF8Map();
    CFDataRef UTF8Data = CFDictionaryGetValue(UTF8Map, str);
    if(!UTF8Data) {
        CFIndex length = CFStringGetLength(str);
        UInt8 *buffer = CFAllocatorAllocate(kCFAllocatorDefault, 
                                            CFStringGetMaximumSizeForEncoding(CFStringGetLength(str), kCFStringEncodingUTF8) + 1,
                                            0);
        CFStringGetBytes(str, CFRangeMake(0, length), kCFStringEncodingUTF8, '_', false, buffer, length, &length);
        buffer[length] = '\0';
        UTF8Data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, buffer, length + 1, kCFAllocatorDefault);
        CFDictionarySetValue(UTF8Map, str, UTF8Data);
        CFRelease(UTF8Data);
    }
    checkInUTF8Map();
    return UTF8Data;
}

const char *lwc_string_data(lwc_string *str)
{       
    return (const char *)CFDataGetBytePtr(_lwc_str_UTF8Data(str));
}

size_t lwc_string_length(lwc_string *str)
{       
    return CFDataGetLength(_lwc_str_UTF8Data(str)) - 1;
}

uint32_t lwc_string_hash_value(lwc_string *str)
{
    return (uint32_t)CFHash(str);
}

void lwc_iterate_strings(lwc_iteration_callback_fn cb, void *pw)
{
    CFMutableBagRef context = checkOutContext();
    CFBagApplyFunction(context, (CFBagApplierFunction)cb, pw);
    checkInContext();
}
