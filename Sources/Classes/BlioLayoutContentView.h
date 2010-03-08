//
//  BlioLayoutContentView.h
//  BlioApp
//
//  Created by matt on 03/03/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioLayoutView.h"

@class BlioLayoutTiledLayer;
@class BlioLayoutThumbLayer;
@class BlioLayoutShadowLayer;

@interface BlioLayoutPageLayer : CALayer {
    NSInteger pageNumber;
    BlioLayoutTiledLayer *tiledLayer;
    BlioLayoutThumbLayer *thumbLayer;
    BlioLayoutShadowLayer *shadowLayer;
}

@property (nonatomic) NSInteger pageNumber;

@end

@interface BlioLayoutContentView : UIView {
    id <BlioLayoutDataSource> dataSource;
    NSMutableSet *pageLayers;

}

@property (nonatomic, assign) id <BlioLayoutDataSource> dataSource;
@property (nonatomic, retain) NSMutableSet *pageLayers;

- (BlioLayoutPageLayer *)addPage:(int)aPageNumber retainPages:(NSSet *)pages;

@end
