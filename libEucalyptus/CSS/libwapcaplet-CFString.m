/* libwapcaplet-CFString.m
 *
 * String internment and management tools, converted to be backed with 
 * Apple's CoreFoundation CFStrings, and made thread-safe.
 *
 * Copyright 2011 Things Made Out Of Other Things.
 */

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>

#define lwc_string_s __CFString const

#import "libwapcaplet/libwapcaplet.h"
#import <pthread.h>

static pthread_key_t sContextKey;
static pthread_once_t sContextKeyOnceControl = PTHREAD_ONCE_INIT;

static void ReleaseContext(CFMutableBagRef context)
{
    CFIndex count = CFBagGetCount(context);
    if(count != 0) {
        fprintf(stderr, "WARNING: libwapcaplet context not empty (contains %ld items) on thread ternimation", (long)count);
    }
    CFRelease(context);
}

static void CreateContextKey()
{
    pthread_key_create(&sContextKey, (void (*)(void *))ReleaseContext);
}

static CFMutableBagRef threadContext()
{
    pthread_once(&sContextKeyOnceControl, CreateContextKey);
    CFMutableBagRef context = (CFMutableBagRef)pthread_getspecific(sContextKey);
    if(!context) {
        context = CFBagCreateMutable(kCFAllocatorDefault, 0, &kCFTypeBagCallBacks);
        pthread_setspecific(sContextKey, context);
    }
    return context;
}

lwc_string * lwc_intern_cf_string(CFStringRef str)
{
    CFMutableBagRef context = threadContext();
    CFBagAddValue(context, str);
    return CFBagGetValue(context, str);
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
    CFMutableBagRef context = threadContext();
    CFBagAddValue(context, str);
    //NSCParameterAssert(str == CFBagGetValue(context, str));
    return str;
}

void lwc_string_unref(lwc_string *str)
{
    CFMutableBagRef context = threadContext();
    CFBagRemoveValue(context, str);
}

lwc_error lwc_string_caseless_isequal(lwc_string *str1, lwc_string *str2, bool *ret)
{
    *ret = ((str1 == str2) || (CFStringCompare(str1, str2, kCFCompareCaseInsensitive) == kCFCompareEqualTo));
    return lwc_error_ok;
}

const char *lwc_string_data(lwc_string *str)
{       
    const char * o1 = CFStringGetCStringPtr(str, kCFStringEncodingUTF8);
    if(o1) {
        return o1;
    } else {
        return [(NSString *)str UTF8String];
    }
}

size_t lwc_string_length(lwc_string *str)
{       
    size_t ret = strlen(lwc_string_data(str));
    return ret;
}

uint32_t lwc_string_hash_value(lwc_string *str)
{
    return (uint32_t)CFHash(str);
}

void lwc_iterate_strings(lwc_iteration_callback_fn cb, void *pw)
{
    CFMutableBagRef context = threadContext();
    CFBagApplyFunction(context, (CFBagApplierFunction)cb, pw);
}
