//
//  LDImageStack.h
//  Image Stack Reference
//
//  Created by Lee Daffen on 03/05/2013.
//  Copyright (c) 2013 Lee Daffen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>


@class LDImageStack;


@protocol LDImageStackDataSource <NSObject>

- (NSUInteger)numberOfImageViewsInStack;
- (UIImageView *)imageStack:(LDImageStack *)imageStack imageViewAtIndex:(NSInteger)index;

@end


@protocol LDImageStackDelegate <NSObject>

@end


@interface LDImageStack : UIView

@property (nonatomic, weak) id<LDImageStackDataSource> dataSource;
@property (nonatomic, weak) id<LDImageStackDelegate> delegate;

@end
