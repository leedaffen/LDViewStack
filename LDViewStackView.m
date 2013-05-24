//
//  LDViewStackView.m
//  Yoga
//
//  Created by Lee Daffen on 09/05/2013.
//  Copyright (c) 2013 Sam Dean. All rights reserved.
//

#import "LDViewStackView.h"


const CGFloat kBorderWidth = 4.0f;
const CGFloat kShadowRadius = 3.0f;
const CGFloat kShadowOpacity = 0.35f;
const CGFloat kShadowOffsetX = 2.0f;
const CGFloat kShadowOffsetY = 2.0f;


float randomRotationAngle() {
    // provides random rotations over an arc -π/36rad to π/36rad (approx. 344 to 16 deg)
    Float32 angle = arc4random()/((pow(2, 32)-1)) * M_PI/36;
    Boolean neg = arc4random()%2<1? false : true;
    
    if (neg)
        angle = 0-angle;
    
    return angle;
}

@implementation LDViewStackView

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        CGRect f = self.frame;
        f.size.width = f.size.width + (2*kBorderWidth);
        f.size.height = f.size.height + (2*kBorderWidth);
        f.origin.x = f.origin.x - kBorderWidth;
        f.origin.y = f.origin.y - kBorderWidth;
        self.frame = f;
    }
    return self;
}

- (void)setDisplayView:(UIView *)displayView {
    if (_displayView != displayView) {
        if (nil != _displayView)
            [self removeDisplayView];
        
        _displayView = displayView;
        CGRect f = _displayView.frame;
        f.origin.x = f.origin.x + kBorderWidth;
        f.origin.y = f.origin.y + kBorderWidth;
        _displayView.frame = f;
        
        [self addSubview:displayView];
    }
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    
    // add a shadow
    self.layer.shouldRasterize = YES;
    self.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.layer.shadowOffset = CGSizeMake(kShadowOffsetX, kShadowOffsetY);
    self.layer.shadowRadius = kShadowRadius;
    self.layer.shadowOpacity = kShadowOpacity;
    
    // add border
    self.layer.borderColor = UIColor.whiteColor.CGColor;
    self.layer.borderWidth = kBorderWidth;
    
    // apply random rotation transform
    self.rotationAngle = randomRotationAngle();
    self.transform = CGAffineTransformRotate(self.transform, self.rotationAngle);
}

- (void)removeDisplayView {
    [_displayView removeFromSuperview];
    _displayView = nil;
}

@end

