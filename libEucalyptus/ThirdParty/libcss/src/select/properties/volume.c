/*
 * This file is part of LibCSS
 * Licensed under the MIT License,
 *		  http://www.opensource.org/licenses/mit-license.php
 * Copyright 2009 John-Mark Bell <jmb@netsurf-browser.org>
 */

#include "bytecode/bytecode.h"
#include "bytecode/opcodes.h"
#include "select/propset.h"
#include "select/propget.h"
#include "utils/utils.h"

#include "select/properties/properties.h"
#include "select/properties/helpers.h"

css_error cascade_volume(uint32_t opv, css_style *style, 
		css_select_state *state)
{
	uint16_t value = 0;
	css_fixed val = 0;
	uint32_t unit = UNIT_PCT;

	if (isInherit(opv) == false) {
		switch (getValue(opv)) {
		case VOLUME_NUMBER:
			value = 0;

			val = *((css_fixed *) style->bytecode);
			advance_bytecode(style, sizeof(val));
			break;
		case VOLUME_DIMENSION:
			value = 0;

			val = *((css_fixed *) style->bytecode);
			advance_bytecode(style, sizeof(val));
			unit = *((uint32_t *) style->bytecode);
			advance_bytecode(style, sizeof(unit));
			break;
		case VOLUME_SILENT:
		case VOLUME_X_SOFT:
		case VOLUME_SOFT:
		case VOLUME_MEDIUM:
		case VOLUME_LOUD:
		case VOLUME_X_LOUD:
			/** \todo convert to public values */
			break;
		}
	}

	unit = to_css_unit(unit);

	if (outranks_existing(getOpcode(opv), isImportant(opv), state,
			isInherit(opv))) {
		/** \todo volume */
	}

	return CSS_OK;
}

css_error set_volume_from_hint(const css_hint *hint,
		css_computed_style *style)
{
	UNUSED(hint);
	UNUSED(style);

	return CSS_OK;
}

css_error initial_volume(css_select_state *state)
{
	UNUSED(state);

	return CSS_OK;
}

css_error compose_volume(const css_computed_style *parent,
		const css_computed_style *child,
		css_computed_style *result)
{
	UNUSED(parent);
	UNUSED(child);
	UNUSED(result);

	return CSS_OK;
}

uint32_t destroy_volume(void *bytecode)
{
	uint32_t value = getValue(*((uint32_t*)bytecode));
	uint32_t additional = 0;
	if (value == VOLUME_NUMBER)
		additional = sizeof(css_fixed);
	else if (value == VOLUME_DIMENSION)
		additional = sizeof(css_fixed) + sizeof(uint32_t);
	
	return sizeof(uint32_t) + additional;
}
