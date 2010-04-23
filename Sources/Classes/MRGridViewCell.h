//
//  MRGridViewCell.h
//
//  Created by Sean Doherty on 3/10/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
	MRGridViewCellEditingStyleNone,
	MRGridViewCellEditingStyleDelete,
	MRGridViewCellEditingStyleInsert
} MRGridViewCellEditingStyle;

@interface MRGridViewCell : UIView {
	NSString* reuseIdentifier;
	UIView * contentView;
	UIButton * deleteButton;
	NSString * cellContentDescription;
}
@property(readwrite,copy,nonatomic) NSString* reuseIdentifier;
@property(readwrite,copy,nonatomic) NSString* cellContentDescription;
@property(readwrite,retain,nonatomic) UIView* contentView;
@property(readwrite,retain,nonatomic) UIButton* deleteButton;
-(id) initWithFrame:(CGRect)frame reuseIdentifier:(NSString*)identifier;
-(void) prepareForReuse;
@end
