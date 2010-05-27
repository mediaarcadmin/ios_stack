//
//  MRGridViewCell.h
//
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//	Licensed to K-NFB Reading Technology, Inc. for use in the Blio iPhone OS Application.
//	Please refer to the Licensing Agreement for terms and conditions.

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
