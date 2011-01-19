/*
 * This file is part of LibCSS.
 * Licensed under the MIT License,
 *		  http://www.opensource.org/licenses/mit-license.php
 * Copyright 2009 John-Mark Bell <jmb@netsurf-browser.org>
 */

#include <assert.h>
#include <string.h>

#include "bytecode/bytecode.h"
#include "bytecode/opcodes.h"
#include "parse/properties/properties.h"
#include "parse/properties/utils.h"

/**
 * Parse background
 *
 * \param c	  Parsing context
 * \param vector  Vector of tokens to process
 * \param ctx	  Pointer to vector iteration context
 * \param result  Pointer to location to receive resulting style
 * \return CSS_OK on success,
 *	   CSS_NOMEM on memory exhaustion,
 *	   CSS_INVALID if the input is not valid
 *
 * Post condition: \a *ctx is updated with the next token to process
 *		   If the input is invalid, then \a *ctx remains unchanged.
 */
css_error parse_background(css_language *c,
		const parserutils_vector *vector, int *ctx,
		css_style **result)
{
	int orig_ctx = *ctx;
	int prev_ctx;
	const css_token *token;
	css_style *attachment = NULL;
	css_style *color = NULL;
	css_style *image = NULL;
	css_style *position = NULL;
	css_style *repeat = NULL;
	css_style *ret = NULL;
	uint32_t required_size;
	bool match;
	css_error error;

	/* Firstly, handle inherit */
	token = parserutils_vector_peek(vector, *ctx);
	if (token != NULL && token->type == CSS_TOKEN_IDENT &&
			(lwc_string_caseless_isequal(
			token->idata, c->strings[INHERIT],
			&match) == lwc_error_ok && match)) {
		uint32_t *bytecode;

		error = css_stylesheet_style_create(c->sheet, 
				5 * sizeof(uint32_t), &ret);
		if (error != CSS_OK) {
			*ctx = orig_ctx;
			return error;
		}

		bytecode = (uint32_t *) ret->bytecode;

		*(bytecode++) = buildOPV(CSS_PROP_BACKGROUND_ATTACHMENT, 
				FLAG_INHERIT, 0);
		*(bytecode++) = buildOPV(CSS_PROP_BACKGROUND_COLOR,
				FLAG_INHERIT, 0);
		*(bytecode++) = buildOPV(CSS_PROP_BACKGROUND_IMAGE,
				FLAG_INHERIT, 0);
		*(bytecode++) = buildOPV(CSS_PROP_BACKGROUND_POSITION,
				FLAG_INHERIT, 0);
		*(bytecode++) = buildOPV(CSS_PROP_BACKGROUND_REPEAT,
				FLAG_INHERIT, 0);

		parserutils_vector_iterate(vector, ctx);

		*result = ret;

		return CSS_OK;
	} else if (token == NULL) {
		/* No tokens -- clearly garbage */
		*ctx = orig_ctx;
		return CSS_INVALID;
	}

	/* Attempt to parse the various longhand properties */
	do {
		prev_ctx = *ctx;
		error = CSS_OK;

		/* Try each property parser in turn, but only if we
		 * haven't already got a value for this property.
		 * To achieve this, we end up with a bunch of empty
		 * if/else statements. Perhaps there's a clearer way 
		 * of expressing this. */
		if (attachment == NULL && 
				(error = parse_background_attachment(c, vector,
				ctx, &attachment)) == CSS_OK) {
		} else if (color == NULL && 
				(error = parse_background_color(c, vector, ctx,
				&color)) == CSS_OK) {
		} else if (image == NULL && 
				(error = parse_background_image(c, vector, ctx,
				&image)) == CSS_OK) {
		} else if (position == NULL &&
				(error = parse_background_position(c, vector, 
				ctx, &position)) == CSS_OK) {
		} else if (repeat == NULL &&
				(error = parse_background_repeat(c, vector, 
				ctx, &repeat)) == CSS_OK) {
		}

		if (error == CSS_OK) {
			consumeWhitespace(vector, ctx);

			token = parserutils_vector_peek(vector, *ctx);
		} else {
			/* Forcibly cause loop to exit */
			token = NULL;
		}
	} while (*ctx != prev_ctx && token != NULL);

	/* Calculate the required size of the resultant style,
	 * defaulting the unspecified properties to their initial values */
	required_size = 0;

	if (attachment)
		required_size += attachment->length;
	else
		required_size += sizeof(uint32_t);

	if (color)
		required_size += color->length;
	else
		required_size += sizeof(uint32_t);

	if (image)
		required_size += image->length;
	else
		required_size += sizeof(uint32_t);

	if (position)
		required_size += position->length;
	else
		required_size += sizeof(uint32_t); /* Use top left, not 0% 0% */

	if (repeat)
		required_size += repeat->length;
	else
		required_size += sizeof(uint32_t);

	/* Create and populate it */
	error = css_stylesheet_style_create(c->sheet, required_size, &ret);
	if (error != CSS_OK)
		goto cleanup;

	required_size = 0;

	if (attachment) {
		memcpy(((uint8_t *) ret->bytecode) + required_size,
				attachment->bytecode, attachment->length);
		required_size += attachment->length;
	} else {
		void *bc = ((uint8_t *) ret->bytecode) + required_size;

		*((uint32_t *) bc) = buildOPV(CSS_PROP_BACKGROUND_ATTACHMENT,
				0, BACKGROUND_ATTACHMENT_SCROLL);
		required_size += sizeof(uint32_t);
	}

	if (color) {
		memcpy(((uint8_t *) ret->bytecode) + required_size,
				color->bytecode, color->length);
		required_size += color->length;
	} else {
		void *bc = ((uint8_t *) ret->bytecode) + required_size;

		*((uint32_t *) bc) = buildOPV(CSS_PROP_BACKGROUND_COLOR,
				0, BACKGROUND_COLOR_TRANSPARENT);
		required_size += sizeof(uint32_t);
	}

	if (image) {
		memcpy(((uint8_t *) ret->bytecode) + required_size,
				image->bytecode, image->length);
		required_size += image->length;
	} else {
		void *bc = ((uint8_t *) ret->bytecode) + required_size;

		*((uint32_t *) bc) = buildOPV(CSS_PROP_BACKGROUND_IMAGE,
				0, BACKGROUND_IMAGE_NONE);
		required_size += sizeof(uint32_t);
	}

	if (position) {
		memcpy(((uint8_t *) ret->bytecode) + required_size,
				position->bytecode, position->length);
		required_size += position->length;
	} else {
		void *bc = ((uint8_t *) ret->bytecode) + required_size;

		*((uint32_t *) bc) = buildOPV(CSS_PROP_BACKGROUND_POSITION,
				0, BACKGROUND_POSITION_HORZ_LEFT |
				BACKGROUND_POSITION_VERT_TOP);
		required_size += sizeof(uint32_t);
	}

	if (repeat) {
		memcpy(((uint8_t *) ret->bytecode) + required_size,
				repeat->bytecode, repeat->length);
		required_size += repeat->length;
	} else {
		void *bc = ((uint8_t *) ret->bytecode) + required_size;

		*((uint32_t *) bc) = buildOPV(CSS_PROP_BACKGROUND_REPEAT,
				0, BACKGROUND_REPEAT_REPEAT);
		required_size += sizeof(uint32_t);
	}

	assert(required_size == ret->length);

	/* Write the result */
	*result = ret;
	/* Invalidate ret, so that cleanup doesn't destroy it */
	ret = NULL;

	/* Clean up after ourselves */
cleanup:
	if (attachment)
		css_stylesheet_style_destroy(c->sheet, attachment, error == CSS_OK);
	if (color)
		css_stylesheet_style_destroy(c->sheet, color, error == CSS_OK);
	if (image)
		css_stylesheet_style_destroy(c->sheet, image, error == CSS_OK);
	if (position)
		css_stylesheet_style_destroy(c->sheet, position, error == CSS_OK);
	if (repeat)
		css_stylesheet_style_destroy(c->sheet, repeat, error == CSS_OK);
	if (ret)
		css_stylesheet_style_destroy(c->sheet, ret, error == CSS_OK);

	if (error != CSS_OK)
		*ctx = orig_ctx;

	return error;
}






