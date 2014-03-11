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

@property (nonatomic, weak) IBOutlet id<LDViewStackDataSource> dataSource;
@property (nonatomic, weak) IBOutlet id<LDViewStackDelegate> delegate;


/*
 * Duration of the shuffle animation
 * This triggers after dragging ends and slides the selected view to the bottom of the stack
 */
@property (nonatomic, assign) CGFloat shuffleAnimationDuration;

/*
 * Controls the number of 'visible' views
 * If set to 1 only the top-most view is displayed
 * Defaults to 3
 */
@property (nonatomic, assign) NSUInteger maxVisibleItems;

/*
 * Prevent translations in X and/or Y axis
 * Both default to NO
 */
@property (nonatomic, assign) BOOL preventX;
@property (nonatomic, assign) BOOL preventY;

/*
 * OPTIONAL - view into which the stack will be temporarily placed when dragging (used prevent bounds-clipping from parent views)
 */
@property (nonatomic, weak) UIView *overlayParentView;

/*
 * Update the contents of the stack from the data source
 */
- (void)reloadData;

@end
