//
//  LDImageStack.h
//  Image Stack Reference
//
//  Created by Lee Daffen on 03/05/2013.
//  Copyright (c) 2013 Lee Daffen. All rights reserved.
//
//
//  Renders a stack of UIImageViews in which the top image can be dragged away to be replaced by the next image in the stack
//  The removed image is then added to the bottom of the stack
//
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>


@class LDImageStack;


@protocol LDImageStackDataSource <NSObject>

- (NSUInteger)numberOfImageViewsInStack;
- (UIImageView *)imageStack:(LDImageStack *)imageStack imageViewAtIndex:(NSInteger)index;

@end


@protocol LDImageStackDelegate <NSObject>

@optional
- (void)imageStack:(LDImageStack *)imageStack didMoveNewImageViewToTopOfStack:(UIImageView *)imageView;

@end


@interface LDImageStack : UIView

@property (nonatomic, weak) id<LDImageStackDataSource> dataSource;
@property (nonatomic, weak) id<LDImageStackDelegate> delegate;
@property (nonatomic, assign) CGFloat shuffleAnimationDuration;

- (void)reloadData;

@end
