/* libwapcaplet.h
 *
 * String internment and management tools.
 *
 * Copyright 2009 The NetSurf Browser Project.
 *		  Daniel Silverstone <dsilvers@netsurf-browser.org>
 */

#ifndef libwapcaplet_h_
#define libwapcaplet_h_

#include <sys/types.h>
#include <stdbool.h>
#include <stdint.h>

/**
 * Memory allocator type
 */
typedef void *(*lwc_allocator_fn)(void *ptr, size_t size, void *pw);

/**
 * A string internment context.
 */
typedef struct lwc_context_s lwc_context;

/**
 * An interned string.
 */
typedef struct lwc_string_s lwc_string;

/**
 * Error codes which libwapcaplet might return.
 */
typedef enum lwc_error_e {
	lwc_error_ok		= 0,
	lwc_error_oom		= 1,
        lwc_error_range		= 2
} lwc_error;

/**
 * Create an internment context.
 *
 * This creates an internment context with a weak ref of one.
 *
 * You should reference the context with lwc_context_ref to convert
 * that to a strong reference when you decide where to store it.
 */
extern lwc_error lwc_create_context(lwc_allocator_fn alloc, void *pw,
				    lwc_context **ret);

/**
 * Increment the reference count for an internment context.
 */
extern lwc_context *lwc_context_ref(lwc_context *ctx);

/**
 * Decrement the reference count for an internment context.
 *
 * @note If the reference count reaches zero, the context will be freed.
 */
extern void lwc_context_unref(lwc_context *ctx);

/**
 * Intern a string.
 *
 * If the string was already present, its reference count is incremented.
 *
 * The returned string is guaranteed to be NUL-terminated.
 */
extern lwc_error lwc_context_intern(lwc_context *ctx,
				    const char *s, size_t slen,
				    lwc_string **ret);

/**
 * Intern a substring.
 */
extern lwc_error lwc_context_intern_substring(lwc_context *ctx,
					      lwc_string *str,
					      size_t ssoffset, size_t sslen,
					      lwc_string **ret);

/**
 * Increment the reference count on an lwc_string.
 *
 * Use this if copying the string and intending both sides to retain
 * ownership.
 */
extern lwc_string *lwc_context_string_ref(lwc_context *ctx, lwc_string *str);

/**
 * Release a reference on an lwc_string.
 *
 * If the reference count reaches zero then the string will be freed.
 */
extern void lwc_context_string_unref(lwc_context *ctx, lwc_string *str);

/**
 * Check if two interned strings are equal.
 *
 * @note The strings must be from the same intern context and that
 *	 must be the context passed in.
 */
#define lwc_context_string_isequal(ctx, str1, str2, ret) \
	(*ret = (str1 == str2)), lwc_error_ok

/**
 * Check if two interned strings are case-insensitively equal.
 *
 * @note The strings must be from the same intern context and that
 *	 must be the context passed in.
 */
extern lwc_error lwc_context_string_caseless_isequal(lwc_context *ctx,
                                                     lwc_string *str1,
                                                     lwc_string *str2,
                                                     bool *ret);
/**
 * Retrieve the data pointer for an interned string.
 *
 * @note The data we point at belongs to the string and will
 *       die with the string. Keep a ref if you need it.
 */
extern const char *lwc_string_data(lwc_string *str);

/**
 * Retrieve the data length for an interned string.
 *
 * @note The data we point at belongs to the string and will
 *       die with the string. Keep a ref if you need it.
 */
extern size_t lwc_string_length(lwc_string *str);

/**
 * Retrieve (or compute if unavailable) a hash value for the content of the string.
 *
 * @note This API should only be used as a convenient way to retrieve a hash
 *       value for the string. This hash value should not be relied on to be
 *       unique within an invocation of the program, nor should it be relied upon
 *       to be stable between invocations of the program. Never use the hash
 *       value as a way to directly identify the value of the string.
 */
extern uint32_t lwc_string_hash_value(lwc_string *str);

/**
 * Retrieve the size, in bytes, of internment context \a ctx.
 */
extern size_t lwc_context_size(lwc_context *ctx);

#endif /* libwapcaplet_h_ */
