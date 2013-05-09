//
//  LDViewStackView.m
//  Yoga
//
//  Created by Lee Daffen on 09/05/2013.
//  Copyright (c) 2013 Sam Dean. All rights reserved.
//

#import "LDViewStackView.h"

float randomRotationAngle() {
    // provides random rotations over an arc -π/24rad to π/24rad (approx. 336 to 24 deg)
    Float32 angle = arc4random()/((pow(2, 32)-1)) * M_PI/24;
    Boolean neg = arc4random()%2<1? false : true;
    
    if (neg)
        angle = 0-angle;
    
    return angle;
}

@implementation LDViewStackView

- (void)setDisplayView:(UIView *)displayView {
    if (_displayView != displayView) {
        if (nil != _displayView) {
            [_displayView removeFromSuperview];
            _displayView = nil;
        }
        
        _displayView = displayView;
        
        [self addSubview:displayView];
    }
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    
    // add a shadow
    self.layer.shouldRasterize = YES;
    self.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.layer.shadowOffset = CGSizeMake(2.0f, 2.0f);
    self.layer.shadowRadius = 3.0f;
    self.layer.shadowOpacity = 0.35f;
    
    // add border
    self.layer.borderColor = UIColor.whiteColor.CGColor;
    self.layer.borderWidth = 4.0f;
    
    // apply random rotation transform
    self.rotationAngle = randomRotationAngle();
    self.transform = CGAffineTransformRotate(self.transform, self.rotationAngle);
}

@end

