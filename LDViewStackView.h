//
//  LDViewStackView.h
//  Yoga
//
//  Created by Lee Daffen on 09/05/2013.
//  Copyright (c) 2013 Sam Dean. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface LDViewStackView : UIView

@property (nonatomic, strong) UIView *displayView;
@property (nonatomic, assign) CGFloat rotationAngle;

- (void)removeDisplayView;

@end
