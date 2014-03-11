//
//  LDViewStackView.h
//  Yoga
//
//  Created by Lee Daffen on 09/05/2013.
//  Copyright (c) 2013 Lee Daffen. All rights reserved.
//
//
// Internal container view implementation
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface LDViewStackView : UIView

@property (nonatomic, weak) UIView *displayView;
@property (nonatomic, assign) CGFloat rotationAngle;

- (void)removeDisplayView;

@end
