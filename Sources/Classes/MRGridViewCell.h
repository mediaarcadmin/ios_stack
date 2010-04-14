//
//  MRGridViewCell.h
//
//  Created by Sean Doherty on 3/10/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MRGridViewCell : UIView {
	NSString* reuseIdentifier;
}
@property(readwrite,copy,nonatomic) NSString* reuseIdentifier;
-(id) initWithFrame:(CGRect)frame reuseIdentifier:(NSString*)identifier;
-(void) prepareForReuse;
@end
