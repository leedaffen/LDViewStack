//
//  LDViewStack.h
//  View Stack
//
//  Created by Lee Daffen on 03/05/2013.
//  Copyright (c) 2013 Lee Daffen. All rights reserved.
//
//
//  Renders a stack of UIViews in which the top view can be dragged away to be replaced by the next view in the stack
//  The removed view is then added to the bottom of the stack
//
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>


@class LDViewStack;


@protocol LDViewStackDataSource <NSObject>

- (NSUInteger)numberOfViewsInStack;
- (UIView *)viewStack:(LDViewStack *)viewStack viewAtIndex:(NSInteger)index;

@end


@protocol LDViewStackDelegate <NSObject>

@optional
- (void)viewStack:(LDViewStack *)viewStack didMoveViewToTopOfStack:(UIView *)imageView;

@end


@interface LDViewStack : UIView

@property (nonatomic, weak) id<LDViewStackDataSource> dataSource;
@property (nonatomic, weak) id<LDViewStackDelegate> delegate;
@property (nonatomic, assign) CGFloat shuffleAnimationDuration;

- (void)reloadData;

@end
