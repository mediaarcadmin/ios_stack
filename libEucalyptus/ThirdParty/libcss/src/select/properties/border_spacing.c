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

css_error cascade_border_spacing(uint32_t opv, css_style *style, 
		css_select_state *state)
{
	uint16_t value = CSS_BORDER_SPACING_INHERIT;
	css_fixed hlength = 0;
	css_fixed vlength = 0;
	uint32_t hunit = UNIT_PX;
	uint32_t vunit = UNIT_PX;

	if (isInherit(opv) == false) {
		value = CSS_BORDER_SPACING_SET;
		hlength = *((css_fixed *) style->bytecode);
		advance_bytecode(style, sizeof(hlength));
		hunit = *((uint32_t *) style->bytecode);
		advance_bytecode(style, sizeof(hunit));

		vlength = *((css_fixed *) style->bytecode);
		advance_bytecode(style, sizeof(vlength));
		vunit = *((uint32_t *) style->bytecode);
		advance_bytecode(style, sizeof(vunit));
	}

	hunit = to_css_unit(hunit);
	vunit = to_css_unit(vunit);

	if (outranks_existing(getOpcode(opv), isImportant(opv), state,
			isInherit(opv))) {
		return set_border_spacing(state->computed, value,
				hlength, hunit, vlength, vunit);
	}

	return CSS_OK;
}

css_error set_border_spacing_from_hint(const css_hint *hint, 
		css_computed_style *style)
{
	return set_border_spacing(style, hint->status,
		hint->data.position.h.value, hint->data.position.h.unit,
		hint->data.position.v.value, hint->data.position.v.unit);
}

css_error initial_border_spacing(css_select_state *state)
{
	return set_border_spacing(state->computed, CSS_BORDER_SPACING_SET,
			0, CSS_UNIT_PX, 0, CSS_UNIT_PX);
}

css_error compose_border_spacing(const css_computed_style *parent,
		const css_computed_style *child,
		css_computed_style *result)
{
	css_fixed hlength = 0, vlength = 0;
	css_unit hunit = CSS_UNIT_PX, vunit = CSS_UNIT_PX;
	uint8_t type = get_border_spacing(child, &hlength, &hunit, 
			&vlength, &vunit);

	if ((child->uncommon == NULL && parent->uncommon != NULL) || 
			type == CSS_BORDER_SPACING_INHERIT ||
			(child->uncommon != NULL && result != child)) {
		if ((child->uncommon == NULL && parent->uncommon != NULL) || 
				type == CSS_BORDER_SPACING_INHERIT) {
			type = get_border_spacing(parent, 
					&hlength, &hunit, &vlength, &vunit);
		}

		return set_border_spacing(result, type, hlength, hunit, 
				vlength, vunit);
	}

	return CSS_OK;
}

uint32_t destroy_border_spacing(void *bytecode)
{
	bool has_values = (getValue(*((uint32_t*)bytecode)) == BORDER_SPACING_SET);
	
	return sizeof(uint32_t) + (has_values ? (sizeof(css_fixed) + sizeof(uint32_t)) * 2 : 0);
}
