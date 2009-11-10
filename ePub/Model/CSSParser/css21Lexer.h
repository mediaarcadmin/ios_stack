/** \file
 *  This C header file was generated by $ANTLR version 3.2 Sep 23, 2009 12:02:23
 *
 *     -  From the grammar source file : css21.g
 *     -                            On : 2009-11-10 12:39:15
 *     -                 for the lexer : css21LexerLexer *
 * Editing it, at least manually, is not wise. 
 *
 * C language generator and runtime by Jim Idle, jimi|hereisanat|idle|dotgoeshere|ws.
 *
 *
 * The lexer css21Lexer has the callable functions (rules) shown below,
 * which will invoke the code for the associated rule in the source grammar
 * assuming that the input stream is pointing to a token/text stream that could begin
 * this rule.
 * 
 * For instance if you call the first (topmost) rule in a parser grammar, you will
 * get the results of a full parse, but calling a rule half way through the grammar will
 * allow you to pass part of a full token stream to the parser, such as for syntax checking
 * in editors and so on.
 *
 * The parser entry points are called indirectly (by function pointer to function) via
 * a parser context typedef pcss21Lexer, which is returned from a call to css21LexerNew().
 *
 * As this is a generated lexer, it is unlikely you will call it 'manually'. However
 * the methods are provided anyway.
 * * The methods in pcss21Lexer are  as follows:
 *
 *  -  void      pcss21Lexer->HEXCHAR(pcss21Lexer)
 *  -  void      pcss21Lexer->NONASCII(pcss21Lexer)
 *  -  void      pcss21Lexer->UNICODE(pcss21Lexer)
 *  -  void      pcss21Lexer->ESCAPE(pcss21Lexer)
 *  -  void      pcss21Lexer->NMSTART(pcss21Lexer)
 *  -  void      pcss21Lexer->NMCHAR(pcss21Lexer)
 *  -  void      pcss21Lexer->NAME(pcss21Lexer)
 *  -  void      pcss21Lexer->URL(pcss21Lexer)
 *  -  void      pcss21Lexer->A(pcss21Lexer)
 *  -  void      pcss21Lexer->B(pcss21Lexer)
 *  -  void      pcss21Lexer->C(pcss21Lexer)
 *  -  void      pcss21Lexer->D(pcss21Lexer)
 *  -  void      pcss21Lexer->E(pcss21Lexer)
 *  -  void      pcss21Lexer->F(pcss21Lexer)
 *  -  void      pcss21Lexer->G(pcss21Lexer)
 *  -  void      pcss21Lexer->H(pcss21Lexer)
 *  -  void      pcss21Lexer->I(pcss21Lexer)
 *  -  void      pcss21Lexer->J(pcss21Lexer)
 *  -  void      pcss21Lexer->K(pcss21Lexer)
 *  -  void      pcss21Lexer->L(pcss21Lexer)
 *  -  void      pcss21Lexer->M(pcss21Lexer)
 *  -  void      pcss21Lexer->N(pcss21Lexer)
 *  -  void      pcss21Lexer->O(pcss21Lexer)
 *  -  void      pcss21Lexer->P(pcss21Lexer)
 *  -  void      pcss21Lexer->Q(pcss21Lexer)
 *  -  void      pcss21Lexer->R(pcss21Lexer)
 *  -  void      pcss21Lexer->S(pcss21Lexer)
 *  -  void      pcss21Lexer->T(pcss21Lexer)
 *  -  void      pcss21Lexer->U(pcss21Lexer)
 *  -  void      pcss21Lexer->V(pcss21Lexer)
 *  -  void      pcss21Lexer->W(pcss21Lexer)
 *  -  void      pcss21Lexer->X(pcss21Lexer)
 *  -  void      pcss21Lexer->Y(pcss21Lexer)
 *  -  void      pcss21Lexer->Z(pcss21Lexer)
 *  -  void      pcss21Lexer->COMMENT(pcss21Lexer)
 *  -  void      pcss21Lexer->CDO(pcss21Lexer)
 *  -  void      pcss21Lexer->CDC(pcss21Lexer)
 *  -  void      pcss21Lexer->INCLUDES(pcss21Lexer)
 *  -  void      pcss21Lexer->DASHMATCH(pcss21Lexer)
 *  -  void      pcss21Lexer->GREATER(pcss21Lexer)
 *  -  void      pcss21Lexer->LBRACE(pcss21Lexer)
 *  -  void      pcss21Lexer->RBRACE(pcss21Lexer)
 *  -  void      pcss21Lexer->LBRACKET(pcss21Lexer)
 *  -  void      pcss21Lexer->RBRACKET(pcss21Lexer)
 *  -  void      pcss21Lexer->OPEQ(pcss21Lexer)
 *  -  void      pcss21Lexer->SEMI(pcss21Lexer)
 *  -  void      pcss21Lexer->COLON(pcss21Lexer)
 *  -  void      pcss21Lexer->SOLIDUS(pcss21Lexer)
 *  -  void      pcss21Lexer->MINUS(pcss21Lexer)
 *  -  void      pcss21Lexer->PLUS(pcss21Lexer)
 *  -  void      pcss21Lexer->STAR(pcss21Lexer)
 *  -  void      pcss21Lexer->LPAREN(pcss21Lexer)
 *  -  void      pcss21Lexer->RPAREN(pcss21Lexer)
 *  -  void      pcss21Lexer->COMMA(pcss21Lexer)
 *  -  void      pcss21Lexer->DOT(pcss21Lexer)
 *  -  void      pcss21Lexer->NOTVALID(pcss21Lexer)
 *  -  void      pcss21Lexer->STRING(pcss21Lexer)
 *  -  void      pcss21Lexer->IDENT(pcss21Lexer)
 *  -  void      pcss21Lexer->HASH(pcss21Lexer)
 *  -  void      pcss21Lexer->IMPORT(pcss21Lexer)
 *  -  void      pcss21Lexer->PAGE(pcss21Lexer)
 *  -  void      pcss21Lexer->MEDIA(pcss21Lexer)
 *  -  void      pcss21Lexer->CHARSET(pcss21Lexer)
 *  -  void      pcss21Lexer->IMPORTANT(pcss21Lexer)
 *  -  void      pcss21Lexer->EMS(pcss21Lexer)
 *  -  void      pcss21Lexer->EXS(pcss21Lexer)
 *  -  void      pcss21Lexer->LENGTH(pcss21Lexer)
 *  -  void      pcss21Lexer->ANGLE(pcss21Lexer)
 *  -  void      pcss21Lexer->TIME(pcss21Lexer)
 *  -  void      pcss21Lexer->FREQ(pcss21Lexer)
 *  -  void      pcss21Lexer->DIMENSION(pcss21Lexer)
 *  -  void      pcss21Lexer->PERCENTAGE(pcss21Lexer)
 *  -  void      pcss21Lexer->NUMBER(pcss21Lexer)
 *  -  void      pcss21Lexer->URI(pcss21Lexer)
 *  -  void      pcss21Lexer->WS(pcss21Lexer)
 *  -  void      pcss21Lexer->NL(pcss21Lexer)
 *  -  void      pcss21Lexer->Tokens(pcss21Lexer)
 *
 * The return type for any particular rule is of course determined by the source
 * grammar file.
 */
// [The "BSD licence"]
// Copyright (c) 2005-2009 Jim Idle, Temporal Wave LLC
// http://www.temporal-wave.com
// http://www.linkedin.com/in/jimidle
//
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
// 3. The name of the author may not be used to endorse or promote products
//    derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
// OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
// NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
// THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#ifndef	_css21Lexer_H
#define _css21Lexer_H
/* =============================================================================
 * Standard antlr3 C runtime definitions
 */
#include    <antlr3.h>

/* End of standard antlr 3 runtime definitions
 * =============================================================================
 */
 
#ifdef __cplusplus
extern "C" {
#endif

// Forward declare the context typedef so that we can use it before it is
// properly defined. Delegators and delegates (from import statements) are
// interdependent and their context structures contain pointers to each other
// C only allows such things to be declared if you pre-declare the typedef.
//
typedef struct css21Lexer_Ctx_struct css21Lexer, * pcss21Lexer;



#ifdef	ANTLR3_WINDOWS
// Disable: Unreferenced parameter,							- Rules with parameters that are not used
//          constant conditional,							- ANTLR realizes that a prediction is always true (synpred usually)
//          initialized but unused variable					- tree rewrite variables declared but not needed
//          Unreferenced local variable						- lexer rule declares but does not always use _type
//          potentially unitialized variable used			- retval always returned from a rule 
//			unreferenced local function has been removed	- susually getTokenNames or freeScope, they can go without warnigns
//
// These are only really displayed at warning level /W4 but that is the code ideal I am aiming at
// and the codegen must generate some of these warnings by necessity, apart from 4100, which is
// usually generated when a parser rule is given a parameter that it does not use. Mostly though
// this is a matter of orthogonality hence I disable that one.
//
#pragma warning( disable : 4100 )
#pragma warning( disable : 4101 )
#pragma warning( disable : 4127 )
#pragma warning( disable : 4189 )
#pragma warning( disable : 4505 )
#pragma warning( disable : 4701 )
#endif

/* ========================
 * BACKTRACKING IS ENABLED
 * ========================
 */

/** Context tracking structure for css21Lexer
 */
struct css21Lexer_Ctx_struct
{
    /** Built in ANTLR3 context tracker contains all the generic elements
     *  required for context tracking.
     */
    pANTLR3_LEXER    pLexer;


     void (*mHEXCHAR)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mNONASCII)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mUNICODE)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mESCAPE)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mNMSTART)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mNMCHAR)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mNAME)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mURL)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mA)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mB)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mC)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mD)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mE)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mF)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mG)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mH)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mI)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mJ)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mK)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mL)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mM)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mN)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mO)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mP)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mQ)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mR)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mS)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mT)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mU)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mV)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mW)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mX)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mY)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mZ)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mCOMMENT)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mCDO)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mCDC)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mINCLUDES)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mDASHMATCH)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mGREATER)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mLBRACE)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mRBRACE)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mLBRACKET)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mRBRACKET)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mOPEQ)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mSEMI)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mCOLON)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mSOLIDUS)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mMINUS)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mPLUS)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mSTAR)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mLPAREN)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mRPAREN)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mCOMMA)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mDOT)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mNOTVALID)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mSTRING)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mIDENT)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mHASH)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mIMPORT)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mPAGE)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mMEDIA)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mCHARSET)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mIMPORTANT)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mEMS)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mEXS)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mLENGTH)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mANGLE)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mTIME)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mFREQ)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mDIMENSION)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mPERCENTAGE)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mNUMBER)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mURI)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mWS)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mNL)	(struct css21Lexer_Ctx_struct * ctx);
     void (*mTokens)	(struct css21Lexer_Ctx_struct * ctx);    const char * (*getGrammarFileName)();
    void	    (*free)   (struct css21Lexer_Ctx_struct * ctx);
        
};

// Function protoypes for the constructor functions that external translation units
// such as delegators and delegates may wish to call.
//
ANTLR3_API pcss21Lexer css21LexerNew         (pANTLR3_INPUT_STREAM instream);
ANTLR3_API pcss21Lexer css21LexerNewSSD      (pANTLR3_INPUT_STREAM instream, pANTLR3_RECOGNIZER_SHARED_STATE state);

/** Symbolic definitions of all the tokens that the lexer will work with.
 * \{
 *
 * Antlr will define EOF, but we can't use that as it it is too common in
 * in C header files and that would be confusing. There is no way to filter this out at the moment
 * so we just undef it here for now. That isn't the value we get back from C recognizers
 * anyway. We are looking for ANTLR3_TOKEN_EOF.
 */
#ifdef	EOF
#undef	EOF
#endif
#ifdef	Tokens
#undef	Tokens
#endif 
#define STAR      30
#define MEDIUM      5
#define LBRACE      18
#define MEDIA      17
#define CHARSET      11
#define EOF      -1
#define DECLARATION      7
#define LENGTH      40
#define LPAREN      35
#define INCLUDES      32
#define LBRACKET      29
#define TIME      44
#define RPAREN      36
#define IMPORT      14
#define NAME      52
#define GREATER      25
#define SELECTOR      6
#define ESCAPE      49
#define COMMA      16
#define IDENT      20
#define DIMENSION      85
#define PLUS      24
#define FREQ      45
#define NL      86
#define RBRACKET      34
#define COMMENT      80
#define DOT      28
#define D      57
#define E      58
#define F      59
#define G      60
#define A      54
#define B      55
#define RBRACE      19
#define ANGLE      43
#define C      56
#define L      65
#define M      66
#define NMCHAR      51
#define N      67
#define O      68
#define H      61
#define I      62
#define DECLARATIONLIST      8
#define J      63
#define NUMBER      38
#define K      64
#define HASH      27
#define HEXCHAR      46
#define U      74
#define T      73
#define W      76
#define V      75
#define Q      70
#define P      69
#define S      72
#define MINUS      26
#define VALUE      10
#define R      71
#define CDO      81
#define SOLIDUS      23
#define SEMI      13
#define CDC      82
#define PERCENTAGE      39
#define UNICODE      48
#define URL      53
#define Y      78
#define X      77
#define IMPORTANT      37
#define URI      15
#define Z      79
#define COLON      22
#define NOTVALID      83
#define PAGE      21
#define NMSTART      50
#define WS      84
#define DASHMATCH      33
#define OPEQ      31
#define PROPERTY      9
#define EMS      41
#define EXS      42
#define NONASCII      47
#define RULESET      4
#define STRING      12
#ifdef	EOF
#undef	EOF
#define	EOF	ANTLR3_TOKEN_EOF
#endif

#ifndef TOKENSOURCE
#define TOKENSOURCE(lxr) lxr->pLexer->rec->state->tokSource
#endif

/* End of token definitions for css21Lexer
 * =============================================================================
 */
/** \} */

#ifdef __cplusplus
}
#endif

#endif

/* END - Note:Keep extra line feed to satisfy UNIX systems */
