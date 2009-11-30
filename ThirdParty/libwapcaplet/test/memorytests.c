/* test/basictests.c
 *
 * Basic tests for the test suite for libwapcaplet
 *
 * Copyright 2009 The NetSurf Browser Project
 *                Daniel Silverstone <dsilvers@netsurf-browser.org>
 */

#include <check.h>
#include <stdlib.h>

#include "tests.h"

/**** Simple tracking allocator ****/

typedef enum {
        NONE, ALLOC, FREE
} alloc_op;

static unsigned long bytes = 0;
static unsigned long allocs = 0;
static void *last_pw = NULL;
static alloc_op last_op = NONE;

static void *
tracking_allocator(void *ptr, size_t len, void *pw)
{
        void *ret;
        last_pw = pw;
        if (ptr == NULL) {
                last_op = ALLOC;
                bytes += len;
                allocs++;
                ret = malloc(len + sizeof(size_t));
                *(size_t *)ret = len;
                return ((char *) ret) + sizeof(size_t);
        }
        last_op = FREE;
        allocs--;
        bytes -= *(((size_t *)ptr) - 1);
        free((((size_t *)ptr) - 1));
        return NULL;
}

static lwc_context *ctx = NULL;

static void
with_tracked_alloc_setup(void)
{
        fail_unless(lwc_create_context(tracking_allocator, NULL, &ctx) == lwc_error_ok,
                    "Unable to create context");
        fail_unless(allocs == 1,
                    "Creating a context used more than one alloc?");
        fail_unless(lwc_context_ref(ctx) == ctx,
                    "Reffing the context failed to return the context.");
}

static void
with_tracked_alloc_teardown(void)
{
        lwc_context_unref(ctx);
        fail_unless(allocs == 0,
                    "Unreffing the context failed to free everything left.");
}

START_TEST (test_tracking_one_intern)
{
        lwc_string *str;
        fail_unless(lwc_context_intern(ctx, "one", 3, &str) == lwc_error_ok,
                    "Unable to intern 'one'");
        fail_unless(allocs == 2,
                    "Interning a string into a fresh context didn't.");
}
END_TEST

START_TEST (test_tracking_one_intern_twice)
{
        lwc_string *str;
        fail_unless(lwc_context_intern(ctx, "one", 3, &str) == lwc_error_ok,
                    "Unable to intern 'one'");
        fail_unless(allocs == 2,
                    "Interning a string into a fresh context didn't.");
        fail_unless(lwc_context_intern(ctx, "one", 3, &str) == lwc_error_ok,
                    "Unable to intern 'one' again");
        fail_unless(allocs == 2,
                    "Interning a string again still did.");
}
END_TEST

START_TEST (test_tracking_two_interns)
{
        lwc_string *one, *ONE;
        fail_unless(lwc_context_intern(ctx, "one", 3, &one) == lwc_error_ok,
                    "Unable to intern 'one'");
        fail_unless(allocs == 2,
                    "Interning a string into a fresh context didn't.");
        fail_unless(lwc_context_intern(ctx, "ONE", 3, &ONE) == lwc_error_ok,
                    "Unable to intern 'one' again");
        fail_unless(allocs == 3,
                    "Interning a new string didn't.");
}
END_TEST

START_TEST (test_tracking_two_interns_caseless1)
{
        lwc_string *one, *ONE;
        bool comp = false;
        fail_unless(lwc_context_intern(ctx, "one", 3, &one) == lwc_error_ok,
                    "Unable to intern 'one'");
        fail_unless(allocs == 2,
                    "Interning a string into a fresh context didn't.");
        fail_unless(lwc_context_intern(ctx, "ONE", 3, &ONE) == lwc_error_ok,
                    "Unable to intern 'ONE'");
        fail_unless(allocs == 3,
                    "Interning a new string didn't.");
        fail_unless(lwc_context_string_caseless_isequal(ctx, one, ONE, &comp) == lwc_error_ok,
                    "Unable to caseless compare");
        fail_unless(allocs == 3,
                    "Caseless compare created worthless new values");
        fail_unless(comp == true,
                    "Caseless compare failed to spot that 'one' and 'ONE' are the same");
}
END_TEST

START_TEST (test_tracking_two_interns_caseless2)
{
        lwc_string *one, *ONE;
        bool comp = false;
        fail_unless(lwc_context_intern(ctx, "oNe", 3, &one) == lwc_error_ok,
                    "Unable to intern 'oNe'");
        fail_unless(allocs == 2,
                    "Interning a string into a fresh context didn't.");
        fail_unless(lwc_context_intern(ctx, "ONE", 3, &ONE) == lwc_error_ok,
                    "Unable to intern 'ONE'");
        fail_unless(allocs == 3,
                    "Interning a new string didn't.");
        fail_unless(lwc_context_string_caseless_isequal(ctx, one, ONE, &comp) == lwc_error_ok,
                    "Unable to caseless compare");
        fail_unless(allocs == 4,
                    "Caseless compare didn't make one caseless 'one'");
        fail_unless(comp == true,
                    "Caseless compare failed to spot that 'oNe' and 'ONE' are the same");
}
END_TEST

START_TEST (test_tracking_caseless_unref1)
{
        lwc_string *one, *ONE;
        bool comp = false;
        fail_unless(lwc_context_intern(ctx, "one", 3, &one) == lwc_error_ok,
                    "Unable to intern 'one'");
        fail_unless(allocs == 2,
                    "Interning a string into a fresh context didn't.");
        fail_unless(lwc_context_intern(ctx, "ONE", 3, &ONE) == lwc_error_ok,
                    "Unable to intern 'ONE'");
        fail_unless(allocs == 3,
                    "Interning a new string didn't.");
        fail_unless(lwc_context_string_caseless_isequal(ctx, one, ONE, &comp) == lwc_error_ok,
                    "Unable to caseless compare");
        fail_unless(allocs == 3,
                    "Caseless compare made pointless additional 'one'");
        fail_unless(comp == true,
                    "Caseless compare failed to spot that 'oNe' and 'ONE' are the same");
        
        lwc_context_string_unref(ctx, ONE);
        fail_unless(allocs == 2, "Unreffing 'ONE' failed to free something");
}
END_TEST

START_TEST (test_tracking_caseless_unref2)
{
        lwc_string *one, *ONE;
        bool comp = false;
        fail_unless(lwc_context_intern(ctx, "one", 3, &one) == lwc_error_ok,
                    "Unable to intern 'one'");
        fail_unless(allocs == 2,
                    "Interning a string into a fresh context didn't.");
        fail_unless(lwc_context_intern(ctx, "ONE", 3, &ONE) == lwc_error_ok,
                    "Unable to intern 'ONE'");
        fail_unless(allocs == 3,
                    "Interning a new string didn't.");
        fail_unless(lwc_context_string_caseless_isequal(ctx, one, ONE, &comp) == lwc_error_ok,
                    "Unable to caseless compare");
        fail_unless(allocs == 3,
                    "Caseless compare made pointless additional 'one'");
        fail_unless(comp == true,
                    "Caseless compare failed to spot that 'oNe' and 'ONE' are the same");
        
        lwc_context_string_unref(ctx, ONE);
        fail_unless(allocs == 2, "Unreffing 'ONE' failed to free something");

        lwc_context_string_unref(ctx, one);
        fail_unless(allocs == 1, "Unreffing 'one' failed to free something");
}
END_TEST

START_TEST (test_tracking_caseless_unref3)
{
        lwc_string *one, *ONE;
        bool comp = false;
        fail_unless(lwc_context_intern(ctx, "one", 3, &one) == lwc_error_ok,
                    "Unable to intern 'one'");
        fail_unless(allocs == 2,
                    "Interning a string into a fresh context didn't.");
        fail_unless(lwc_context_intern(ctx, "ONE", 3, &ONE) == lwc_error_ok,
                    "Unable to intern 'ONE'");
        fail_unless(allocs == 3,
                    "Interning a new string didn't.");
        fail_unless(lwc_context_string_caseless_isequal(ctx, one, ONE, &comp) == lwc_error_ok,
                    "Unable to caseless compare");
        fail_unless(allocs == 3,
                    "Caseless compare made pointless additional 'one'");
        fail_unless(comp == true,
                    "Caseless compare failed to spot that 'oNe' and 'ONE' are the same");
        
        lwc_context_string_unref(ctx, one);
        fail_unless(allocs == 3, "Unreffing 'one' freed something");

        lwc_context_string_unref(ctx, ONE);
        fail_unless(allocs == 1, "Unreffing 'ONE' failed to free both things");
}
END_TEST

/**** And the suites are set up here ****/

void
lwc_memory_suite(SRunner *sr)
{
        Suite *s = suite_create("libwapcaplet: Memory allocation tests");
        TCase *tc_mem = tcase_create("memory");
        
        tcase_add_checked_fixture(tc_mem, with_tracked_alloc_setup,
                                  with_tracked_alloc_teardown);
        
        tcase_add_test(tc_mem, test_tracking_one_intern);
        tcase_add_test(tc_mem, test_tracking_one_intern_twice);
        tcase_add_test(tc_mem, test_tracking_two_interns);
        tcase_add_test(tc_mem, test_tracking_two_interns_caseless1);
        tcase_add_test(tc_mem, test_tracking_two_interns_caseless2);
        tcase_add_test(tc_mem, test_tracking_caseless_unref1);
        tcase_add_test(tc_mem, test_tracking_caseless_unref2);
        tcase_add_test(tc_mem, test_tracking_caseless_unref3);
        
        suite_add_tcase(s, tc_mem);
        srunner_add_suite(sr, s);
}
