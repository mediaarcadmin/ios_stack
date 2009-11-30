/* test/basictests.c
 *
 * Basic tests for the test suite for libwapcaplet
 *
 * Copyright 2009 The NetSurf Browser Project
 *                Daniel Silverstone <dsilvers@netsurf-browser.org>
 */

#include <check.h>
#include <stdlib.h>
#include <string.h>

#include "tests.h"

static void *last_pw = NULL;
static void *
trivial_alloc_fn(void *p, size_t s, void *pw)
{
        last_pw = pw;
        return realloc(p, s);
}

#ifndef NDEBUG
/* All the basic assert() tests */
START_TEST (test_lwc_context_creation_bad_alloc_aborts)
{
        lwc_context *ctx = NULL;
        lwc_error err;
        
        err = lwc_create_context(NULL, NULL, &ctx);
}
END_TEST

START_TEST (test_lwc_context_destruction_aborts)
{
        lwc_context_unref(NULL);  
}
END_TEST

START_TEST (test_lwc_context_ref_aborts)
{
        lwc_context_ref(NULL);
}
END_TEST

START_TEST (test_lwc_context_unref_aborts)
{
        lwc_context_unref(NULL);
}
END_TEST

START_TEST (test_lwc_context_intern_aborts1)
{
        lwc_context_intern(NULL, NULL, 0, NULL);
}
END_TEST

START_TEST (test_lwc_context_intern_aborts2)
{
        lwc_context *ctx;
        
        fail_unless(lwc_create_context(trivial_alloc_fn, NULL, &ctx) == lwc_error_ok,
                    "Unable to create context");
        
        lwc_context_intern(ctx, NULL, 0, NULL);
}
END_TEST

START_TEST (test_lwc_context_intern_aborts3)
{
        lwc_context *ctx;
        
        fail_unless(lwc_create_context(trivial_alloc_fn, NULL, &ctx) == lwc_error_ok,
                    "Unable to create context");
        
        lwc_context_intern(ctx, "A", 1, NULL);
}
END_TEST

START_TEST (test_lwc_context_intern_substring_aborts1)
{
        lwc_context_intern_substring(NULL, NULL, 0, 0, NULL);
}
END_TEST

START_TEST (test_lwc_context_intern_substring_aborts2)
{
        lwc_context *ctx;
        fail_unless(lwc_create_context(trivial_alloc_fn, NULL, &ctx) == lwc_error_ok,
                    "Unable to create context");
        
        lwc_context_intern_substring(ctx, NULL, 0, 0, NULL);
}
END_TEST

START_TEST (test_lwc_context_intern_substring_aborts3)
{
        lwc_context *ctx;
        lwc_string *str;
        fail_unless(lwc_create_context(trivial_alloc_fn, NULL, &ctx) == lwc_error_ok,
                    "Unable to create context");
        fail_unless(lwc_context_intern(ctx, "Jam", 3, &str) == lwc_error_ok,
                    "unable to intern 'Jam'");
        
        lwc_context_intern_substring(ctx, str, 100, 1, NULL);
}
END_TEST

START_TEST (test_lwc_context_intern_substring_aborts4)
{
        lwc_context *ctx;
        lwc_string *str;
        fail_unless(lwc_create_context(trivial_alloc_fn, NULL, &ctx) == lwc_error_ok,
                    "Unable to create context");
        fail_unless(lwc_context_intern(ctx, "Jam", 3, &str) == lwc_error_ok,
                    "unable to intern 'Jam'");
        
        lwc_context_intern_substring(ctx, str, 1, 10, NULL);
}
END_TEST

START_TEST (test_lwc_context_intern_substring_aborts5)
{
        lwc_context *ctx;
        lwc_string *str;
        fail_unless(lwc_create_context(trivial_alloc_fn, NULL, &ctx) == lwc_error_ok,
                    "Unable to create context");
        fail_unless(lwc_context_intern(ctx, "Jam", 3, &str) == lwc_error_ok,
                    "unable to intern 'Jam'");
        
        lwc_context_intern_substring(ctx, str, 1, 2, NULL);
}
END_TEST

START_TEST (test_lwc_context_string_ref_aborts1)
{
        lwc_context_string_ref(NULL, NULL);
}
END_TEST

START_TEST (test_lwc_context_string_ref_aborts2)
{
        lwc_context *ctx;
        fail_unless(lwc_create_context(trivial_alloc_fn, NULL, &ctx) == lwc_error_ok,
                    "Unable to create context");
        lwc_context_string_ref(ctx, NULL);
}
END_TEST

START_TEST (test_lwc_context_string_unref_aborts1)
{
        lwc_context_string_unref(NULL, NULL);
}
END_TEST

START_TEST (test_lwc_context_string_unref_aborts2)
{
        lwc_context *ctx;
        fail_unless(lwc_create_context(trivial_alloc_fn, NULL, &ctx) == lwc_error_ok,
                    "Unable to create context");
        lwc_context_string_unref(ctx, NULL);
}
END_TEST

START_TEST (test_lwc_string_data_aborts)
{
        lwc_string_data(NULL);
}
END_TEST

START_TEST (test_lwc_string_length_aborts)
{
        lwc_string_length(NULL);
}
END_TEST

START_TEST (test_lwc_string_hash_value_aborts)
{
        lwc_string_hash_value(NULL);
}
END_TEST

START_TEST (test_lwc_context_size_aborts)
{
        lwc_context_size(NULL);
}
END_TEST

#endif

START_TEST (test_lwc_context_creation_ok)
{
        lwc_context *ctx = NULL;
        lwc_error err;
        
        err = lwc_create_context(trivial_alloc_fn, NULL, &ctx);
        fail_unless(ctx != NULL,
                    "Unable to create context");
        fail_unless(err == lwc_error_ok,
                    "Created context but returned !ok");
}
END_TEST

START_TEST (test_lwc_context_destruction_ok)
{
        lwc_context *ctx = NULL;
        
        fail_unless(lwc_create_context(trivial_alloc_fn, NULL, &ctx) == lwc_error_ok,
                    "Unable to create context");
        
        lwc_context_unref(ctx);
}
END_TEST

START_TEST (test_lwc_reffed_context_destruction_ok)
{
        lwc_context *ctx = NULL;
        
        fail_unless(lwc_create_context(trivial_alloc_fn, NULL, &ctx) == lwc_error_ok,
                    "Unable to create context");
        
        lwc_context_ref(ctx); /* make the weak ref strong */
        
        lwc_context_unref(ctx);
}
END_TEST

/**** The next set of tests need a fixture set ****/

static lwc_context *shared_ctx;

static void
with_simple_context_setup(void)
{
        fail_unless(lwc_create_context(trivial_alloc_fn, NULL,
                                       &shared_ctx) == lwc_error_ok,
                    "Unable to create context");
        lwc_context_ref(shared_ctx);
}

static void
with_simple_context_teardown(void)
{
        lwc_context_unref(shared_ctx);
}

START_TEST (test_lwc_context_intern_ok)
{
        lwc_string *str = NULL;
        fail_unless(lwc_context_intern(shared_ctx, "A", 1, &str) == lwc_error_ok,
                    "Unable to intern a simple string");
        fail_unless(str != NULL,
                    "Returned OK but str was still NULL");
}
END_TEST

START_TEST (test_lwc_context_intern_twice_ok)
{
        lwc_string *str1 = NULL, *str2 = NULL;
        fail_unless(lwc_context_intern(shared_ctx, "A", 1, &str1) == lwc_error_ok,
                    "Unable to intern a simple string");
        fail_unless(str1 != NULL,
                    "Returned OK but str was still NULL");
        fail_unless(lwc_context_intern(shared_ctx, "B", 1, &str2) == lwc_error_ok,
                    "Unable to intern a simple string");
        fail_unless(str2 != NULL,
                    "Returned OK but str was still NULL");
}
END_TEST

START_TEST (test_lwc_context_intern_twice_same_ok)
{
        lwc_string *str1 = NULL, *str2 = NULL;
        fail_unless(lwc_context_intern(shared_ctx, "A", 1, &str1) == lwc_error_ok,
                    "Unable to intern a simple string");
        fail_unless(str1 != NULL,
                    "Returned OK but str was still NULL");
        fail_unless(lwc_context_intern(shared_ctx, "A", 1, &str2) == lwc_error_ok,
                    "Unable to intern a simple string");
        fail_unless(str2 != NULL,
                    "Returned OK but str was still NULL");
}
END_TEST

START_TEST (test_lwc_context_size_non_zero)
{
        fail_unless(lwc_context_size(shared_ctx) > 0,
                    "Size of empty context is zero");
}
END_TEST

START_TEST (test_lwc_context_size_updated_on_string_intern)
{
        size_t empty_size = lwc_context_size(shared_ctx);
        lwc_string *str;

        fail_unless(empty_size > 0,
                    "Size of empty context is zero");

        fail_unless(lwc_context_intern(shared_ctx, "one", 3, &str) == lwc_error_ok,
                    "Unable to intern a simple string");

        fail_unless(lwc_context_size(shared_ctx) > empty_size,
                    "Post-intern context size is same or smaller than empty size");
}
END_TEST

START_TEST (test_lwc_context_size_updated_on_string_unref)
{
        size_t empty_size = lwc_context_size(shared_ctx);
        lwc_string *str;

        fail_unless(empty_size > 0,
                    "Size of empty context is zero");

        fail_unless(lwc_context_intern(shared_ctx, "one", 3, &str) == lwc_error_ok,
                    "Unable to intern a simple string");

        fail_unless(lwc_context_size(shared_ctx) > empty_size,
                    "Post-intern context size is same or smaller than empty size");

        lwc_context_string_unref(shared_ctx, str);

        fail_unless(lwc_context_size(shared_ctx) == empty_size,
                    "Post-unref context size is not the same as empty size");
}
END_TEST

START_TEST (test_lwc_context_size_updated_on_substring_intern)
{
        size_t empty_size = lwc_context_size(shared_ctx);
	size_t post_intern_size = 0;
        lwc_string *str, *str2;

        fail_unless(empty_size > 0,
                    "Size of empty context is zero");

        fail_unless(lwc_context_intern(shared_ctx, "one", 3, &str) == lwc_error_ok,
                    "Unable to intern a simple string");

        post_intern_size = lwc_context_size(shared_ctx);

        fail_unless(post_intern_size > empty_size,
                    "Post-intern context size is same or smaller than empty size");

        fail_unless(lwc_context_intern_substring(shared_ctx, str, 0, 1, &str2) == lwc_error_ok,
                    "Failed to intern substring");

        fail_unless(lwc_context_size(shared_ctx) > post_intern_size,
                    "Post-substring-intern context size is same or smaller than pre-substring-intern size");
}
END_TEST

START_TEST (test_lwc_context_size_updated_on_substring_unref)
{
        size_t empty_size = lwc_context_size(shared_ctx);
	size_t post_intern_size = 0;
        lwc_string *str, *str2;

        fail_unless(empty_size > 0,
                    "Size of empty context is zero");

        fail_unless(lwc_context_intern(shared_ctx, "one", 3, &str) == lwc_error_ok,
                    "Unable to intern a simple string");

        post_intern_size = lwc_context_size(shared_ctx);

        fail_unless(post_intern_size > empty_size,
                    "Post-intern context size is same or smaller than empty size");

        fail_unless(lwc_context_intern_substring(shared_ctx, str, 0, 1, &str2) == lwc_error_ok,
                    "Failed to intern substring");

        fail_unless(lwc_context_size(shared_ctx) > post_intern_size,
                    "Post-substring-intern context size is same or smaller than pre-substring-intern size");

        lwc_context_string_unref(shared_ctx, str2);

        fail_unless(lwc_context_size(shared_ctx) == post_intern_size,
                    "Post-substring-unref size is not the same as pre-substring-intern size");
}
END_TEST

/**** The next set of tests need a fixture set with some strings ****/

static lwc_string *intern_one = NULL, *intern_two = NULL, *intern_three = NULL;

static void
with_filled_context_setup(void)
{
        fail_unless(lwc_create_context(trivial_alloc_fn, NULL,
                                       &shared_ctx) == lwc_error_ok,
                    "Unable to create context");
        lwc_context_ref(shared_ctx);
        
        fail_unless(lwc_context_intern(shared_ctx, "one", 3, &intern_one) == lwc_error_ok,
                    "Unable to intern 'one'");
        fail_unless(lwc_context_intern(shared_ctx, "two", 3, &intern_two) == lwc_error_ok,
                    "Unable to intern 'one'");
        fail_unless(lwc_context_intern(shared_ctx, "three", 5, &intern_three) == lwc_error_ok,
                    "Unable to intern 'one'");
        
        fail_unless(intern_one != intern_two, "'one' == 'two'");
        fail_unless(intern_one != intern_three, "'one' == 'three'");
        fail_unless(intern_two != intern_three, "'two' == 'three'");
}

static void
with_filled_context_teardown(void)
{
        lwc_context_unref(shared_ctx);
}

START_TEST (test_lwc_interning_works)
{
        lwc_string *new_one = NULL;
        
        fail_unless(lwc_context_intern(shared_ctx, "one", 3, &new_one) == lwc_error_ok,
                    "Unable to re-intern 'one'");
        
        fail_unless(new_one == intern_one,
                    "Internalising of the string failed");
}
END_TEST

START_TEST (test_lwc_intern_substring)
{
        lwc_string *new_hre = NULL, *sub_hre = NULL;
        
        fail_unless(lwc_context_intern(shared_ctx, "hre", 3,
                                       &new_hre) == lwc_error_ok,
                    "Unable to intern 'hre'");
        fail_unless(lwc_context_intern_substring(shared_ctx, intern_three,
                                                 1, 3, &sub_hre) == lwc_error_ok,
                    "Unable to re-intern 'hre' by substring");
        fail_unless(new_hre == sub_hre,
                    "'hre' != 'hre' -- wow!");
}
END_TEST

START_TEST (test_lwc_context_string_ref_ok)
{
        fail_unless(lwc_context_string_ref(shared_ctx, intern_one) == intern_one,
                    "Oddly, reffing a string didn't return it");
}
END_TEST

START_TEST (test_lwc_context_string_unref_ok)
{
        lwc_context_string_unref(shared_ctx, intern_one);
}
END_TEST

START_TEST (test_lwc_context_string_isequal_ok)
{
        bool result = true;
        fail_unless((lwc_context_string_isequal(shared_ctx, intern_one, 
                                                intern_two, &result)) == lwc_error_ok,
                    "Failure comparing 'one' and 'two'");
        fail_unless(result == false,
                    "'one' == 'two' ?!");
}
END_TEST

START_TEST (test_lwc_context_string_caseless_isequal_ok)
{
        bool result = true;
        lwc_string *new_ONE;
        
        fail_unless(lwc_context_intern(shared_ctx, "ONE", 3, &new_ONE) == lwc_error_ok,
                    "Failure interning 'ONE'");
        
        fail_unless((lwc_context_string_isequal(shared_ctx, intern_one, new_ONE,
                                                &result)) == lwc_error_ok);
        fail_unless(result == false,
                    "'one' == 'ONE' ?!");
        
        fail_unless((lwc_context_string_caseless_isequal(shared_ctx, intern_one, 
                                                         new_ONE, &result)) == lwc_error_ok,
                    "Failure comparing 'one' and 'two'");
        fail_unless(result == true,
                    "'one' !~= 'ONE' ?!");
}
END_TEST

START_TEST (test_lwc_extract_data_ok)
{
        fail_unless(memcmp("one",
                           lwc_string_data(intern_one),
                           lwc_string_length(intern_one)) == 0,
                    "Extracting data ptr etc failed");
}
END_TEST

START_TEST (test_lwc_string_hash_value_ok)
{
        lwc_string_hash_value(intern_one);
}
END_TEST

START_TEST (test_lwc_string_is_nul_terminated)
{
        lwc_string *new_ONE;

        fail_unless(lwc_context_intern(shared_ctx, "ONE", 3, &new_ONE) == lwc_error_ok,
                    "Failure interning 'ONE'");

        fail_unless(lwc_string_data(new_ONE)[lwc_string_length(new_ONE)] == '\0',
                    "Interned string isn't NUL terminated");
}
END_TEST

START_TEST (test_lwc_substring_is_nul_terminated)
{
        lwc_string *new_ONE;
        lwc_string *new_O;

        fail_unless(lwc_context_intern(shared_ctx, "ONE", 3, &new_ONE) == lwc_error_ok,
                    "Failure interning 'ONE'");

        fail_unless(lwc_context_intern_substring(shared_ctx, new_ONE, 0, 1, &new_O) == lwc_error_ok,
                    "Failure interning substring 'O'");

        fail_unless(lwc_string_data(new_O)[lwc_string_length(new_O)] == '\0',
                    "Interned substring isn't NUL terminated");
}
END_TEST

/**** And the suites are set up here ****/

void
lwc_basic_suite(SRunner *sr)
{
        Suite *s = suite_create("libwapcaplet: Basic tests");
        TCase *tc_basic = tcase_create("Creation/Destruction");
        
#ifndef NDEBUG
        tcase_add_test_raise_signal(tc_basic,
                                    test_lwc_context_creation_bad_alloc_aborts,
                                    SIGABRT);
        tcase_add_test_raise_signal(tc_basic,
                                    test_lwc_context_destruction_aborts,
                                    SIGABRT);
        tcase_add_test_raise_signal(tc_basic,
                                    test_lwc_context_ref_aborts,
                                    SIGABRT);
        tcase_add_test_raise_signal(tc_basic,
                                    test_lwc_context_unref_aborts,
                                    SIGABRT);
        tcase_add_test_raise_signal(tc_basic,
                                    test_lwc_context_intern_aborts1,
                                    SIGABRT);
        tcase_add_test_raise_signal(tc_basic,
                                    test_lwc_context_intern_aborts2,
                                    SIGABRT);
        tcase_add_test_raise_signal(tc_basic,
                                    test_lwc_context_intern_aborts3,
                                    SIGABRT);
        tcase_add_test_raise_signal(tc_basic,
                                    test_lwc_context_intern_substring_aborts1,
                                    SIGABRT);
        tcase_add_test_raise_signal(tc_basic,
                                    test_lwc_context_intern_substring_aborts2,
                                    SIGABRT);
        tcase_add_test_raise_signal(tc_basic,
                                    test_lwc_context_intern_substring_aborts3,
                                    SIGABRT);
        tcase_add_test_raise_signal(tc_basic,
                                    test_lwc_context_intern_substring_aborts4,
                                    SIGABRT);
        tcase_add_test_raise_signal(tc_basic,
                                    test_lwc_context_intern_substring_aborts5,
                                    SIGABRT);
        tcase_add_test_raise_signal(tc_basic,
                                    test_lwc_context_string_ref_aborts1,
                                    SIGABRT);
        tcase_add_test_raise_signal(tc_basic,
                                    test_lwc_context_string_ref_aborts2,
                                    SIGABRT);
        tcase_add_test_raise_signal(tc_basic,
                                    test_lwc_context_string_unref_aborts1,
                                    SIGABRT);
        tcase_add_test_raise_signal(tc_basic,
                                    test_lwc_context_string_unref_aborts2,
                                    SIGABRT);
        tcase_add_test_raise_signal(tc_basic,
                                    test_lwc_string_data_aborts,
                                    SIGABRT);
        tcase_add_test_raise_signal(tc_basic,
                                    test_lwc_string_length_aborts,
                                    SIGABRT);
        tcase_add_test_raise_signal(tc_basic,
                                    test_lwc_string_hash_value_aborts,
                                    SIGABRT);
        tcase_add_test_raise_signal(tc_basic,
                                    test_lwc_context_size_aborts,
                                    SIGABRT);
#endif
        
        tcase_add_test(tc_basic, test_lwc_context_creation_ok);
        tcase_add_test(tc_basic, test_lwc_context_destruction_ok);
        tcase_add_test(tc_basic, test_lwc_reffed_context_destruction_ok);
        suite_add_tcase(s, tc_basic);
        
        tc_basic = tcase_create("Ops with a context");
        
        tcase_add_checked_fixture(tc_basic, with_simple_context_setup,
                                  with_simple_context_teardown);
        tcase_add_test(tc_basic, test_lwc_context_intern_ok);
        tcase_add_test(tc_basic, test_lwc_context_intern_twice_ok);
        tcase_add_test(tc_basic, test_lwc_context_intern_twice_same_ok);
        tcase_add_test(tc_basic, test_lwc_context_size_non_zero);
        tcase_add_test(tc_basic, 
                       test_lwc_context_size_updated_on_string_intern);
        tcase_add_test(tc_basic, test_lwc_context_size_updated_on_string_unref);
        tcase_add_test(tc_basic, 
                       test_lwc_context_size_updated_on_substring_intern);
        tcase_add_test(tc_basic, 
                       test_lwc_context_size_updated_on_substring_unref);
        suite_add_tcase(s, tc_basic);
        
        tc_basic = tcase_create("Ops with a filled context");
        
        tcase_add_checked_fixture(tc_basic, with_filled_context_setup,
                                  with_filled_context_teardown);
        tcase_add_test(tc_basic, test_lwc_interning_works);
        tcase_add_test(tc_basic, test_lwc_intern_substring);
        tcase_add_test(tc_basic, test_lwc_context_string_ref_ok);
        tcase_add_test(tc_basic, test_lwc_context_string_unref_ok);
        tcase_add_test(tc_basic, test_lwc_context_string_isequal_ok);
        tcase_add_test(tc_basic, test_lwc_context_string_caseless_isequal_ok);
        tcase_add_test(tc_basic, test_lwc_extract_data_ok);
        tcase_add_test(tc_basic, test_lwc_string_hash_value_ok);
        tcase_add_test(tc_basic, test_lwc_string_is_nul_terminated);
        tcase_add_test(tc_basic, test_lwc_substring_is_nul_terminated);
        suite_add_tcase(s, tc_basic);
        
        srunner_add_suite(sr, s);
}
