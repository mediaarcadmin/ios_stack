//
//  BlioPDFPageParser.m
//  BlioApp
//
//  Created by Matt Farrugia on 05/02/2012.
//  Copyright (c) 2012 BitWink. All rights reserved.
//

#import "BlioPDFPageParser.h"
#import "BlioPDFResourceDataSource.h"
#import "BlioPDFFont.h"

static const NSAttributedString *kBlioPDFLineBreakString;
static const NSAttributedString *kBlioPDFParagraphBreakString;

NSString * const kBlioPDFPositionAttribute = @"BlioPDFPositionAttribute";

@interface BlioPDFPageParser()

@property (nonatomic, assign) id <BlioPDFResourceDataSource> resourceDataSource;
@property (nonatomic, retain) NSMutableArray *unicodeStrings;
@property (nonatomic, assign) CGAffineTransform textMatrix;
@property (nonatomic, assign) CGAffineTransform textLineMatrix;
@property (nonatomic, readonly, assign) CGAffineTransform textStateMatrix;
@property (nonatomic, retain) NSMutableArray *ctmStack;
@property (nonatomic, assign) CGAffineTransform ctm;
@property (nonatomic) CGFloat Tj;
@property (nonatomic) CGFloat Tl;
@property (nonatomic) CGFloat Tc;
@property (nonatomic) CGFloat Tw;
@property (nonatomic) CGFloat Th;
@property (nonatomic) CGFloat Ts;
@property (nonatomic) CGFloat Tfs;
@property (nonatomic) CGFloat userUnit;
@property (nonatomic) CGFloat lastGlyphWidth;
@property (nonatomic) CGAffineTransform rotateTransform;
@property (nonatomic, retain) BlioPDFFont *currentFont;
@property (nonatomic, assign) CGPDFPageRef pageRef;

- (void)updateTextStateMatrix;
- (void)addUnicodeString:(NSString *)encodedString withBytes:(const UInt8 *)bytes length:(NSUInteger)length;
- (void)addParagraphBreak;
- (void)addLineBreak;

@end

static void op_Td(CGPDFScannerRef inScanner, void *info);
static void op_TD(CGPDFScannerRef inScanner, void *info);
static void op_Tm(CGPDFScannerRef inScanner, void *info);
static void op_TSTAR(CGPDFScannerRef inScanner, void *info);
static void op_Tj(CGPDFScannerRef inScanner, void *info);
static void op_TJ(CGPDFScannerRef inScanner, void *info);
static void op_SINGLEQUOTE(CGPDFScannerRef inScanner, void *info);
static void op_DOUBLEQUOTE(CGPDFScannerRef inScanner, void *info);
static void op_Tf (CGPDFScannerRef s, void *info);
static void op_Tc(CGPDFScannerRef inScanner, void *info);
static void op_TL(CGPDFScannerRef inScanner, void *info);
static void op_Ts(CGPDFScannerRef inScanner, void *info);
static void op_Tw(CGPDFScannerRef inScanner, void *info);
static void op_Tz(CGPDFScannerRef inScanner, void *info);
static void op_BT(CGPDFScannerRef inScanner, void *info);
static void op_ET(CGPDFScannerRef inScanner, void *info);
static void op_cm(CGPDFScannerRef inScanner, void *info);
static void op_q(CGPDFScannerRef inScanner, void *info);
static void op_Q(CGPDFScannerRef inScanner, void *info);

@implementation BlioPDFPageParser

@synthesize resourceDataSource;
@synthesize currentFont;
@synthesize textMatrix, textLineMatrix, textStateMatrix, ctmStack, ctm, Tj, Tl, Tc, Tw, Th, Ts, Tfs, userUnit, lastGlyphWidth;
@synthesize pageRef;
@synthesize rotateTransform;
@synthesize unicodeStrings;

+ (void)initialize
{
    if ([[self class] isEqual:NSClassFromString(@"BlioPDFPageParser")]) {
        NSString *lbString = [[NSString alloc] initWithUTF8String:"\u2028"];
        kBlioPDFLineBreakString = [[NSAttributedString alloc] initWithString:lbString];
        [lbString release];
        
        NSString *pbString = [[NSString alloc] initWithUTF8String:"\u2029"];
        kBlioPDFParagraphBreakString = [[NSAttributedString alloc] initWithString:pbString];
        [pbString release];
    }
}

- (void)dealloc
{
    resourceDataSource = nil;
    [unicodeStrings release], unicodeStrings = nil;
    [currentFont release], currentFont = nil;
    [ctmStack release], ctmStack = nil;
    
    [super dealloc];
}

- (id)initWithPageRef:(CGPDFPageRef)aPageRef resourceDataSource:(id<BlioPDFResourceDataSource>)dataSource
{
    if ((self = [super init])) {
        
        pageRef = CGPDFPageRetain(aPageRef);
        resourceDataSource = dataSource;
        
        unicodeStrings = [[NSMutableArray alloc] init];
        rotateTransform = CGAffineTransformIdentity;
        
        textMatrix = CGAffineTransformIdentity;
        textLineMatrix = CGAffineTransformIdentity;
        ctmStack = [[NSMutableArray alloc] init];
        ctm = CGAffineTransformIdentity;
        Th = 1;
        userUnit = 1.0f;
        lastGlyphWidth = -1;
        
    }
    return self;
}

- (void)parse
{
    [self updateTextStateMatrix];
    
    CGPDFOperatorTableRef myTable = CGPDFOperatorTableCreate();
    
    CGPDFOperatorTableSetCallback(myTable, "Tf", &op_Tf);
    CGPDFOperatorTableSetCallback(myTable, "TJ", &op_TJ);
    CGPDFOperatorTableSetCallback(myTable, "Tj", &op_Tj);
    CGPDFOperatorTableSetCallback(myTable, "Td", &op_Td);
    CGPDFOperatorTableSetCallback(myTable, "Tc", &op_Tc);
    CGPDFOperatorTableSetCallback(myTable, "TD", &op_TD);
    CGPDFOperatorTableSetCallback(myTable, "T*", &op_TSTAR);
    CGPDFOperatorTableSetCallback(myTable, "Tc", &op_Tc);
    CGPDFOperatorTableSetCallback(myTable, "TL", &op_TL);
    CGPDFOperatorTableSetCallback(myTable, "Tm", &op_Tm);
    CGPDFOperatorTableSetCallback(myTable, "Ts", &op_Ts);
    CGPDFOperatorTableSetCallback(myTable, "Tw", &op_Tw);
    CGPDFOperatorTableSetCallback(myTable, "Tz", &op_Tz);
    CGPDFOperatorTableSetCallback(myTable, "'", &op_SINGLEQUOTE);
    CGPDFOperatorTableSetCallback(myTable, "\"", &op_DOUBLEQUOTE);
    CGPDFOperatorTableSetCallback(myTable, "BT", &op_BT);
    CGPDFOperatorTableSetCallback(myTable, "ET", &op_ET);
    CGPDFOperatorTableSetCallback(myTable, "cm", &op_cm);
    CGPDFOperatorTableSetCallback(myTable, "q", &op_q);
    CGPDFOperatorTableSetCallback(myTable, "Q", &op_Q);
    
    CGPDFScannerRef myScanner;
    CGPDFContentStreamRef myContentStream;
    CGPDFDictionaryRef dict;
    
    CGPDFReal userUnitNumber;
    CGPDFInteger rotateNumber;
    
    dict = CGPDFPageGetDictionary(pageRef);
    
    if (CGPDFDictionaryGetNumber(dict, "UserUnit", &userUnitNumber)) {
        [self setUserUnit:userUnitNumber];
    }
    
    if (CGPDFDictionaryGetInteger(dict, "Rotate", &rotateNumber)) {
        [self setRotateTransform:CGAffineTransformMakeRotation(M_PI * rotateNumber / 180.0f)];
    }
    
    if (nil != pageRef) {
        myContentStream = CGPDFContentStreamCreateWithPage (pageRef);
        myScanner = CGPDFScannerCreate (myContentStream, myTable, self);
        CGPDFScannerScan (myScanner);
        CGPDFScannerRelease (myScanner);
        CGPDFContentStreamRelease (myContentStream);
    }
    
    CGPDFOperatorTableRelease(myTable);    
}

- (NSString *)string
{
    NSMutableString *completeString = nil;
    
    for (NSAttributedString *attString in self.unicodeStrings) {
        if (!completeString) {
            completeString = [[[NSMutableString alloc] initWithString:[attString string]] autorelease];
        } else {
            [completeString appendString:[attString string]];
        }
    }
    
    return completeString;
}

- (NSAttributedString *)attributedString
{
    NSMutableAttributedString *completeString = nil;
    
    for (NSAttributedString *attString in self.unicodeStrings) {
        
        if (!completeString) {
            completeString = [[[NSMutableAttributedString alloc] initWithAttributedString:attString] autorelease];
        } else {
            [completeString appendAttributedString:attString];
        }
    }
    
    return completeString;
}

- (void)updateTextStateMatrix 
{
    textStateMatrix = CGAffineTransformMake(Tfs*Th, 0, 0, Tfs, 0, Ts);
    //NSLog(@"textStateMatrix: %@", NSStringFromCGAffineTransform(textStateMatrix));
}

- (void)addLineBreak
{
    if ([self.unicodeStrings count]) {
        [self.unicodeStrings addObject:kBlioPDFLineBreakString];
    } 
}

- (void)addParagraphBreak
{
    if ([self.unicodeStrings count]) {
        [self.unicodeStrings addObject:kBlioPDFParagraphBreakString];
    }
}

- (void)addUnicodeString:(NSString *)encodedString withBytes:(const UInt8 *)bytes length:(NSUInteger)length
{         
    NSString *unicodeString = nil;     
    
    if ([currentFont hasUnicodeMapping]) {
        unicodeString = encodedString;
    } else {
        NSMutableString *allString = [NSMutableString string];
        
        for (int i = 0; i < [encodedString length]; i++) {
            
            NSString *charString = [encodedString substringWithRange:NSMakeRange(i, 1)];        
            const char *charPtr = [charString cStringUsingEncoding:NSUnicodeStringEncoding];
            
            NSString *decoded1 = (NSString *)CFStringCreateWithBytes(NULL, (UInt8 *)charPtr, 1, kCFStringEncodingMacRoman, NO);
            if (decoded1) {
                [allString appendString:decoded1];
                [decoded1 release];
            }
        }
                
        unicodeString = allString;
    }    
    
    if (unicodeString) {
        
        NSMutableAttributedString *positionedString = [[NSMutableAttributedString alloc] initWithString:unicodeString];
        
        for (int i = 0; i < length; i++) {
            //NSLog(@"%@ - %@", NSStringFromCGAffineTransform(textStateMatrix), NSStringFromCGAffineTransform(textMatrix));
            CGAffineTransform textRenderingMatrix = CGAffineTransformConcat(textStateMatrix, textMatrix);
            textRenderingMatrix = CGAffineTransformConcat(textRenderingMatrix, ctm);
            
            unichar characterCode = (unichar)(bytes[i]);
            CGFloat glyphWidth = ([currentFont glyphWidthForCharacter:characterCode])/1000.0f;

            CGFloat Tx, Gx;
            if (characterCode == 32) {
                Tx = ((glyphWidth - (Tj/1000.0f)) * Tfs + Tc + Tw) * Th;
            } else {
                Tx = ((glyphWidth - (Tj/1000.0f)) * Tfs + Tc) * Th;
            }
            Gx = (glyphWidth * Tfs) * Th;
            
            CGRect glyphRect = CGRectMake(- (Tj/1000.0f),0,Gx, Tfs * userUnit);
            CGRect transformedRect = CGRectApplyAffineTransform(glyphRect, textRenderingMatrix);
            //NSLog(@"%@ - %@ - %@", [positionedString string], NSStringFromCGRect(glyphRect), NSStringFromCGRect(transformedRect));     
            
            NSDictionary *attrs = [[NSDictionary alloc] initWithObjectsAndKeys:[NSValue valueWithCGRect:transformedRect], kBlioPDFPositionAttribute, nil];
            [positionedString setAttributes:attrs range:NSMakeRange(i, 1)];
            [attrs release];
            
            Tj = 0;
            CGAffineTransform offsetMatrix = CGAffineTransformMakeTranslation(Tx, 0);
            textMatrix = CGAffineTransformConcat(offsetMatrix, textMatrix);
            //NSLog(@"addUni: %@", NSStringFromCGAffineTransform(textMatrix));
        }
        
        [self.unicodeStrings addObject:positionedString];
        [positionedString release];
    }
}

#pragma mark - Parsing Functions


static void op_Td(CGPDFScannerRef inScanner, void *info) 
{
    /*
     Move to the start of the next line, offset from the start of the current line by (tx , ty ). tx and ty are numbers expressed in unscaled text space units.
     */
    BlioPDFPageParser *parsedPage = info;
    
    CGPDFReal matrix[2];
    BOOL success;
    
    for (int i = 0; i < 2; i++) {
        success = CGPDFScannerPopNumber(inScanner, &matrix[1-i]);
    }
    
    if (success) {        
        [parsedPage setTextLineMatrix:CGAffineTransformTranslate([parsedPage textLineMatrix], matrix[0], matrix[1])];
        [parsedPage setTextMatrix:[parsedPage textLineMatrix]];
        //NSLog(@"opTd: %@", NSStringFromCGAffineTransform([parsedPage textMatrix]));
        [parsedPage addLineBreak];
    }
    
}

static void op_TD(CGPDFScannerRef inScanner, void *info) 
{
    /*
     Move to the start of the next line, offset from the start of the current line by (tx , ty ). As a side effect, this operator sets the leading parameter in the text state. This operator has the same effect as the following code:
     */
    BlioPDFPageParser *parsedPage = info;
    
    CGPDFReal matrix[2];
    BOOL success;
    
    for (int i = 0; i < 2; i++) {
        success = CGPDFScannerPopNumber(inScanner, &matrix[1-i]);
    }
    
    if (success) {
        [parsedPage setTl:-(matrix[1])];        
        [parsedPage setTextLineMatrix:CGAffineTransformTranslate([parsedPage textLineMatrix], matrix[0], matrix[1])];
        [parsedPage setTextMatrix:[parsedPage textLineMatrix]];
        //NSLog(@"opTD: %@", NSStringFromCGAffineTransform([parsedPage textMatrix]));

        [parsedPage addLineBreak];
    }
    
}

static void op_Tm(CGPDFScannerRef inScanner, void *info) 
{
    /*
     Set the text matrix, Tm , and the text line matrix, Tlm :
     */
    BlioPDFPageParser *parsedPage = info;
    
    CGPDFReal matrix[6];
    BOOL success;
    
    for (int i = 0; i < 6; i++) {
        success = CGPDFScannerPopNumber(inScanner, &matrix[5-i]);
    }
    
    if (success) {
        [parsedPage setTextLineMatrix:CGAffineTransformMake(matrix[0], matrix[1], matrix[2], matrix[3], matrix[4], matrix[5])];
        [parsedPage setTextMatrix:[parsedPage textLineMatrix]];
        //NSLog(@"opTm: %@", NSStringFromCGAffineTransform([parsedPage textMatrix]));

        [parsedPage addParagraphBreak];
    }
}

static void op_TSTAR(CGPDFScannerRef inScanner, void *info) 
{
    /*
     Move to the start of the next line. This operator has the same effect as the code 0 Tl Td
     where Tl is the current leading parameter in the text state.
     */
    BlioPDFPageParser *parsedPage = info;
    
    [parsedPage setTextLineMatrix:CGAffineTransformTranslate([parsedPage textLineMatrix], 0, -([parsedPage Tl]))];
    [parsedPage setTextMatrix:[parsedPage textLineMatrix]];
    //NSLog(@"opTDSTAR: %@", NSStringFromCGAffineTransform([parsedPage textMatrix]));

    [parsedPage addLineBreak];
}

// Test-Showing Operators

static void op_Tj(CGPDFScannerRef inScanner, void *info) 
{
    BlioPDFPageParser *parsedPage = info;
    
    CGPDFStringRef string;
    
    BOOL success = CGPDFScannerPopString(inScanner, &string);
    
    if (success) {
        NSString *aString = (NSString *)CGPDFStringCopyTextString(string);
        size_t length = CGPDFStringGetLength(string);
        const UInt8 *bytes = CGPDFStringGetBytePtr(string);
        [parsedPage addUnicodeString:aString withBytes:bytes length:length];
        [aString release];
        
        [parsedPage setTj:0];
    }
}

static void op_TJ(CGPDFScannerRef inScanner, void *info) 
{
    BlioPDFPageParser *parsedPage = info;
    
    CGPDFArrayRef array;
    
    BOOL success = CGPDFScannerPopArray(inScanner, &array);
    
    if (success) {
        for (size_t n = 0; n < CGPDFArrayGetCount(array); n++) {
            if(n >= CGPDFArrayGetCount(array))
                continue;
            
            CGPDFStringRef string;
            success = CGPDFArrayGetString(array, n, &string);
            if (success) {
                NSString *aString = (NSString *)CGPDFStringCopyTextString(string);
                size_t length = CGPDFStringGetLength(string);
                const UInt8 *bytes = CGPDFStringGetBytePtr(string);
                [parsedPage addUnicodeString:aString withBytes:bytes length:length];
                [aString release];
                
            } else {
                CGPDFReal number;
                success = CGPDFArrayGetNumber(array, n, &number);
                if(success)
                {
                    [parsedPage setTj:number];
                }
            }
        }
    }
}

static void op_SINGLEQUOTE(CGPDFScannerRef inScanner, void *info) 
{
    BlioPDFPageParser *parsedPage = info;
    
    [parsedPage setTextLineMatrix:CGAffineTransformTranslate([parsedPage textLineMatrix], 0, -([parsedPage Tl]))];
    [parsedPage setTextMatrix:[parsedPage textLineMatrix]];
    //NSLog(@"opSNGEQUOTE: %@", NSStringFromCGAffineTransform([parsedPage textMatrix]));

    [parsedPage addLineBreak];
    
    CGPDFStringRef string;
    
    BOOL success = CGPDFScannerPopString(inScanner, &string);
    
    if (success) {
        NSString *aString = (NSString *)CGPDFStringCopyTextString(string);
        size_t length = CGPDFStringGetLength(string);
        const UInt8 *bytes = CGPDFStringGetBytePtr(string);
        [parsedPage addUnicodeString:aString withBytes:bytes length:length];
        [aString release];
        
        [parsedPage setTj:0];
    }
}

static void op_DOUBLEQUOTE(CGPDFScannerRef inScanner, void *info) 
{
    BlioPDFPageParser *parsedPage = info;
    CGPDFReal number;
    
    BOOL success = CGPDFScannerPopNumber(inScanner, &number);
    if (success) {
        [parsedPage setTc:number];
    }
    
    success = CGPDFScannerPopNumber(inScanner, &number);
    if (success) {
       [parsedPage setTw:number]; 
    }
    
    [parsedPage setTextLineMatrix:CGAffineTransformTranslate([parsedPage textLineMatrix], 0, -([parsedPage Tl]))];
    [parsedPage setTextMatrix:[parsedPage textLineMatrix]];
    //NSLog(@"opDOUBLEQUOTE: %@", NSStringFromCGAffineTransform([parsedPage textMatrix]));

    [parsedPage addLineBreak];
    
    CGPDFStringRef string;
    
    success = CGPDFScannerPopString(inScanner, &string);
    
    if (success) {
        
        NSString *aString = (NSString *)CGPDFStringCopyTextString(string);
        size_t length = CGPDFStringGetLength(string);
        const UInt8 *bytes = CGPDFStringGetBytePtr(string);
        [parsedPage addUnicodeString:aString withBytes:bytes length:length];
        [aString release];
        
        [parsedPage setTj:0];
    }
}

static void op_Tf (CGPDFScannerRef s, void *info) 
{
    BlioPDFPageParser *parsedPage = info;
    const char *name;
    CGPDFReal number;
    
    if (!CGPDFScannerPopNumber(s, &number)) {
        return;
    }
    
    [parsedPage setTfs:number];
    //NSLog(@"Tfs: %f", [parsedPage Tfs]);
    [parsedPage updateTextStateMatrix];
    
    if (!CGPDFScannerPopName(s, &name))
        return;
    
    BlioPDFFont *font = [[parsedPage resourceDataSource] fontWithName:[NSString stringWithCString:name encoding:NSASCIIStringEncoding] onPageRef:[parsedPage pageRef]];
    
    if (font) {
        [parsedPage setCurrentFont:font];
    }
}

static void op_Tc(CGPDFScannerRef inScanner, void *info) 
{
    BlioPDFPageParser *parsedPage = info;
    CGPDFReal number;
    
    BOOL success = CGPDFScannerPopNumber(inScanner, &number);
    if (success) {
       [parsedPage setTc:number]; 
    }
}

static void op_TL(CGPDFScannerRef inScanner, void *info) 
{
    BlioPDFPageParser *parsedPage = info;
    CGPDFReal number;
    
    BOOL success = CGPDFScannerPopNumber(inScanner, &number);
    if (success) {
        [parsedPage setTl:number];
    }
}

static void op_Ts(CGPDFScannerRef inScanner, void *info) 
{
    BlioPDFPageParser *parsedPage = info;
    CGPDFReal number;
    
    BOOL success = CGPDFScannerPopNumber(inScanner, &number);
    if (success) {
        [parsedPage setTs:number];
        [parsedPage updateTextStateMatrix];
    }    
}

static void op_Tw(CGPDFScannerRef inScanner, void *info) 
{
    BlioPDFPageParser *parsedPage = info;
    CGPDFReal number;
    
    BOOL success = CGPDFScannerPopNumber(inScanner, &number);
    if (success) {
       [parsedPage setTw:number]; 
    }    
}

static void op_Tz(CGPDFScannerRef inScanner, void *info) 
{
    BlioPDFPageParser *parsedPage = info;
    CGPDFReal number;
    
    BOOL success = CGPDFScannerPopNumber(inScanner, &number);
    if (success) {
        [parsedPage setTh:number];
        [parsedPage updateTextStateMatrix];
    }
}

static void op_BT(CGPDFScannerRef inScanner, void *info) 
{
    BlioPDFPageParser *parsedPage = info;
    [parsedPage setTextMatrix:CGAffineTransformIdentity];
    //NSLog(@"opBT: %@", NSStringFromCGAffineTransform([parsedPage textMatrix]));

    [parsedPage setTextLineMatrix:CGAffineTransformIdentity];
    [parsedPage setTj:0];
}

static void op_ET(CGPDFScannerRef inScanner, void *info) 
{
    BlioPDFPageParser *parsedPage = info;
    [parsedPage addParagraphBreak];
}

static void op_cm(CGPDFScannerRef inScanner, void *info) 
{
   
    CGPDFReal matrix[6];
    BOOL success;
    
    for (int i = 0; i < 6; i++) {
        success = CGPDFScannerPopNumber(inScanner, &matrix[5-i]);
    }
    
    if (success) {
        CGAffineTransform ctm = CGAffineTransformMake(matrix[0], matrix[1], matrix[2], matrix[3], matrix[4], matrix[5]);

        BlioPDFPageParser *parsedPage = info;
        [parsedPage setCtm:CGAffineTransformConcat([parsedPage ctm], ctm)];
        //NSLog(@"Op_cm: %@", NSStringFromCGAffineTransform([parsedPage ctm]));
    }
        
}

static void op_q(CGPDFScannerRef inScanner, void *info) 
{
    //NSLog(@"Push CTM");
    BlioPDFPageParser *parsedPage = info;
    [[parsedPage ctmStack] addObject:[NSValue valueWithCGAffineTransform:[parsedPage ctm]]];    
}

static void op_Q(CGPDFScannerRef inScanner, void *info) 
{
    //NSLog(@"Pop CTM");
    BlioPDFPageParser *parsedPage = info;
    [parsedPage setCtm:[[[parsedPage ctmStack] lastObject] CGAffineTransformValue]];    
}  

@end
