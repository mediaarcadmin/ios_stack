#import <Foundation/Foundation.h>
#import "VCTitleCase.h"

// This can be set to 1 or higher to watch memory usage in Instruments.
#define SLEEP_LENGTH 0

void testTitle(NSString *theTitle) {
    NSLog([theTitle titlecaseString]);
    sleep(SLEEP_LENGTH);
}

int main(int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    sleep(SLEEP_LENGTH);

    testTitle(@"Q&A With Steve Jobs: 'That's What Happens In Technology'");
    testTitle(@"What Is AT&T's Problem?");
    testTitle(@"Apple Deal With AT&T Falls Through");
    testTitle(@"this v that");
    testTitle(@"this vs that");
    testTitle(@"this v. that");
    testTitle(@"this vs. that");
    testTitle(@"The SEC's Apple Probe: What You Need to Know");
    testTitle(@"'by the Way, small word at the start but within quotes.'");
    testTitle(@"Small word at end is nothing to be afraid of");
    testTitle(@"Starting Sub-Phrase With a Small Word: a Trick, Perhaps?");
    testTitle(@"Sub-Phrase With a Small Word in Quotes: 'a Trick, Perhaps?'");
    testTitle(@"Sub-Phrase With a Small Word in Quotes: \"a Trick, Perhaps?\"");
    testTitle(@"\"Nothing to Be Afraid of?\"");
    testTitle(@"“Nothing to Be Afraid Of?”");
    testTitle(@"a thing");
    testTitle(@"iTunes isn't a part of iLife.");
    
    [pool drain];
    return 0;
}
