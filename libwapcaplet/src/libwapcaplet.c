/* libwapcaplet.h
 *
 * String internment and management tools.
 *
 * Copyright 2009 The NetSurf Browser Project.
 *		  Daniel Silverstone <dsilvers@netsurf-browser.org>
 */

#include <string.h>
#include <assert.h>

#include "libwapcaplet/libwapcaplet.h"

#ifndef UNUSED
#define UNUSED(x) ((x) = (x))
#endif

typedef uint32_t lwc_hash;
typedef uint32_t lwc_refcounter;

static inline lwc_hash
lwc_calculate_hash(const char *str, size_t len)
{
	lwc_hash z = 0x811c9dc5;
	

	while (len > 0) {
		z *= 0x01000193;
		z ^= *str++;
                len--;
	}

	return z;
}

struct lwc_string_s {
        lwc_string **	prevptr;
        lwc_string *	next;
        size_t		len;
        lwc_hash	hash;
        lwc_refcounter	refcnt;
        lwc_string *	insensitive;
};

#define STR_OF(str) ((char *)(str + 1))
#define CSTR_OF(str) ((const char *)(str + 1))

#define NR_BUCKETS	(4091)

struct lwc_context_s {
        lwc_allocator_fn	alloc;
        void *			alloc_pw;
        lwc_string *		buckets[NR_BUCKETS];
        lwc_refcounter		refcnt;
        bool			refweak;
        size_t			size;
};

lwc_error
lwc_create_context(lwc_allocator_fn alloc, void *pw,
                   lwc_context **ret)
{
        assert(alloc);

        *ret = alloc(NULL, sizeof(lwc_context), pw);
        
        if (*ret == NULL)
                return lwc_error_oom;
        
        memset(*ret, 0, sizeof(lwc_context));
        
        (*ret)->alloc = alloc;
        (*ret)->alloc_pw = pw;
        (*ret)->refcnt = 1;
        (*ret)->refweak = true;
        (*ret)->size = sizeof(lwc_context);
        
        return lwc_error_ok;
}

lwc_context *
lwc_context_ref(lwc_context *ctx)
{
        assert(ctx);
        
        if (ctx->refweak == true)
                ctx->refweak = false;
        else
                ctx->refcnt++;
        
        return ctx;
}

#define LWC_ALLOC(s) ctx->alloc(NULL, s, ctx->alloc_pw)
#define LWC_FREE(p) ctx->alloc(p, 0, ctx->alloc_pw)

void
lwc_context_unref(lwc_context *ctx)
{
        int bucket_nr;
        lwc_string *s, *s_next;
        
        assert(ctx);
        
        if (--(ctx->refcnt))
                return;
        
        for (bucket_nr = 0; bucket_nr < NR_BUCKETS; ++bucket_nr) {
                s = ctx->buckets[bucket_nr];
                while (s != NULL) {
                        s_next = s->next;
                        LWC_FREE(s);
                        s = s_next;
                }
        }
        
        LWC_FREE(ctx);
}

typedef lwc_hash (*lwc_hasher)(const char *, size_t);
typedef int (*lwc_strncmp)(const char *, const char *, size_t);
typedef void (*lwc_memcpy)(char *, const char *, size_t);

static lwc_error
__lwc_context_intern(lwc_context *ctx,
                     const char *s, size_t slen,
                     lwc_string **ret,
                     lwc_hasher hasher,
                     lwc_strncmp compare,
                     lwc_memcpy copy)
{
        lwc_hash h;
        lwc_hash bucket;
        lwc_string *str;
        size_t required_size;
        
        assert(ctx);
        assert((s != NULL) || (slen == 0));
        assert(ret);
        
        h = hasher(s, slen);
        bucket = h % NR_BUCKETS;
        str = ctx->buckets[bucket];
        
        while (str != NULL) {
                if ((str->hash == h) && (str->len == slen)) {
                        if (compare(CSTR_OF(str), s, slen) == 0) {
                                str->refcnt++;
                                *ret = str;
                                return lwc_error_ok;
                        }
                }
                str = str->next;
        }
        
        /* Add one for the additional NUL. */
        required_size = sizeof(lwc_string) + slen + 1;

        *ret = str = LWC_ALLOC(required_size);
        
        if (str == NULL)
                return lwc_error_oom;
        
        str->prevptr = &(ctx->buckets[bucket]);
        str->next = ctx->buckets[bucket];
        if (str->next != NULL)
                str->next->prevptr = &(str->next);
        ctx->buckets[bucket] = str;

        /* Keep context size in sync */
        ctx->size += required_size;
 
        str->len = slen;
        str->hash = h;
        str->refcnt = 1;
        str->insensitive = NULL;
        
        copy(STR_OF(str), s, slen);

        /* Guarantee NUL termination */
        STR_OF(str)[slen] = '\0';
        
        return lwc_error_ok;
}

lwc_error
lwc_context_intern(lwc_context *ctx,
                   const char *s, size_t slen,
                   lwc_string **ret)
{
        return __lwc_context_intern(ctx, s, slen, ret,
                                    lwc_calculate_hash,
                                    strncmp, (lwc_memcpy)memcpy);
}

lwc_error
lwc_context_intern_substring(lwc_context *ctx,
                             lwc_string *str,
                             size_t ssoffset, size_t sslen,
                             lwc_string **ret)
{
        assert(ctx);
        assert(str);
        assert(ret);
        
        if (ssoffset >= str->len)
                return lwc_error_range;
        if ((ssoffset + sslen) > str->len)
                return lwc_error_range;
        
        return lwc_context_intern(ctx, CSTR_OF(str) + ssoffset, sslen, ret);
}

lwc_string *
lwc_context_string_ref(lwc_context *ctx, lwc_string *str)
{
	UNUSED(ctx);

        assert(ctx);
        assert(str);
        
        str->refcnt++;
        
        return str;
}

void
lwc_context_string_unref(lwc_context *ctx, lwc_string *str)
{
        assert(ctx);
        assert(str);
        
        if (--(str->refcnt) > 1)
                return;
        
        if ((str->refcnt == 1) && (str->insensitive != str))
                return;
        
        *(str->prevptr) = str->next;
        
        if (str->next != NULL)
                str->next->prevptr = str->prevptr;

        if (str->insensitive != NULL && str->refcnt == 0)
                lwc_context_string_unref(ctx, str->insensitive);

        /* Reduce context size by appropriate amount (+1 for trailing NUL) */
        ctx->size -= sizeof(lwc_string) + str->len + 1;
       
#ifndef NDEBUG
        memset(str, 0xA5, sizeof(*str) + str->len);
#endif
        
        LWC_FREE(str);
}

/**** Shonky caseless bits ****/

static inline char
dolower(const char c)
{
        if (c >= 'A' && c <= 'Z')
                return c + 'a' - 'A';
        return c;
}

static inline lwc_hash
lwc_calculate_lcase_hash(const char *str, size_t len)
{
	lwc_hash z = 0x811c9dc5;
	

	while (len > 0) {
		z *= 0x01000193;
		z ^= dolower(*str++);
                len--;
	}

	return z;
}

static int
lwc_lcase_strcmp(const char *s1, const char *s2, size_t n)
{
        while (n--) {
                if (*s1++ != dolower(*s2++))
                        return 1;
        }
        return 0;
}

static void
lwc_lcase_memcpy(char *target, const char *source, size_t n)
{
        while (n--) {
                *target++ = dolower(*source++);
        }
}

static lwc_error
lwc_context_intern_caseless(lwc_context *ctx,
                            lwc_string *str)
{
        assert(ctx);
        assert(str);
        assert(str->insensitive == NULL);
        
        return __lwc_context_intern(ctx, CSTR_OF(str),
                                    str->len, &(str->insensitive),
                                    lwc_calculate_lcase_hash,
                                    lwc_lcase_strcmp,
                                    lwc_lcase_memcpy);
        
}

lwc_error
lwc_context_string_caseless_isequal(lwc_context *ctx,
                                    lwc_string *str1,
                                    lwc_string *str2,
                                    bool *ret)
{
        lwc_error err;
        assert(ctx);
        assert(str1);
        assert(str2);
        
        if (str1->insensitive == NULL) {
                err = lwc_context_intern_caseless(ctx, str1);
                if (err != lwc_error_ok)
                        return err;
        }
        if (str2->insensitive == NULL) {
                err = lwc_context_intern_caseless(ctx, str2);
                if (err != lwc_error_ok)
                        return err;
        }
        
        *ret = (str1->insensitive == str2->insensitive);
        return lwc_error_ok;
}

/**** Simple accessors ****/

const char *
lwc_string_data(lwc_string *str)
{
        assert(str);
        
        return CSTR_OF(str);
}

size_t
lwc_string_length(lwc_string *str)
{
        assert(str);
        
        return str->len;
}

uint32_t
lwc_string_hash_value(lwc_string *str)
{
	assert(str);

	return str->hash;
}

size_t
lwc_context_size(lwc_context *ctx)
{
        assert(ctx);

        return ctx->size;
}

