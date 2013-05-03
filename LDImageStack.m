//
//  LDImageStack.m
//  Image Stack Reference
//
//  Created by Lee Daffen on 03/05/2013.
//  Copyright (c) 2013 Lee Daffen. All rights reserved.
//

#import "LDImageStack.h"


#define kShuffleAnimationDuration 0.25f


@interface LDImageStack()

@property (nonatomic, assign) NSUInteger countOfItems;
@property (nonatomic, strong) NSMutableArray *imageViews;
@property (nonatomic, strong) NSMutableArray *imageRotations;

@property (nonatomic, strong) UIImageView *topImageView;
@property (nonatomic, assign) CGRect limitRect;

@property (nonatomic, strong) UIPanGestureRecognizer *pan;

@end


@implementation LDImageStack {
    BOOL _dragging;
    BOOL _animating;
}

- (void)initialise {
    self.userInteractionEnabled = YES;
    
    self.limitRect = CGRectInset(self.bounds, self.bounds.size.width*0.2f, self.bounds.size.height*0.2f);
    
    self.pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self addGestureRecognizer:self.pan];
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self initialise];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self initialise];
    }
    return self;
}

- (CGFloat)rotationAngleForIndex:(NSUInteger)index {
    if (0 == index) return 0;
    
    CGFloat angle = arc4random()/((pow(2, 32)-1)) * M_PI/24;
    BOOL neg = arc4random()%2<1? NO : YES;
    
    if (neg)
        angle = 0-angle;
    
    [self.imageRotations addObject:@(angle)];
    
    return angle;
}

- (UIImageView *)imageViewAtIndex:(NSUInteger)index {
    UIImageView *imageView = [self.dataSource imageStack:self imageViewAtIndex:index];
    imageView.backgroundColor = UIColor.whiteColor;
    imageView.frame = self.bounds;
    
    imageView.layer.shadowColor = UIColor.blackColor.CGColor;
    imageView.layer.shadowOffset = CGSizeMake(2.0f, 2.0f);
    imageView.layer.shadowOpacity = 0.35f;
    imageView.layer.shadowRadius = 3.0f;
    
    imageView.layer.borderColor = UIColor.whiteColor.CGColor;
    imageView.layer.borderWidth = 5.0f;
    
    imageView.layer.shouldRasterize = YES;
    
    imageView.transform = CGAffineTransformRotate(imageView.transform, [self rotationAngleForIndex:index]);
    
    return imageView;
}

- (void)loadDataFromDataSource {
    self.countOfItems = [self.dataSource numberOfImageViewsInStack];
    self.imageViews = [NSMutableArray arrayWithCapacity:self.countOfItems];
    self.imageRotations = [NSMutableArray arrayWithCapacity:self.countOfItems];
    
    for (int index=self.countOfItems-1; index>=0 ; --index) {
        UIImageView *imageView = [self imageViewAtIndex:index];

        [self.imageViews insertObject:imageView atIndex:0];
        [self addSubview:imageView];
    }
    
    if (self.imageViews.count >= 1)
        self.topImageView = self.imageViews[0];
}

- (void)initialiseWithNewDataSource {
    if (nil != self.imageViews) {
        [self.imageViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self.imageViews removeAllObjects];
    }
    
    [self loadDataFromDataSource];
}

- (void)reloadData {
    [self loadDataFromDataSource];
}

- (CGPoint)bestAnimationPoint {
    CGPoint currentPoint = self.topImageView.center;
    CGFloat imageWidth = self.topImageView.bounds.size.width;
    
    CGFloat xIdeal = (currentPoint.x <= self.bounds.size.width/2) ? 0-(imageWidth/2) : self.bounds.size.width+(imageWidth/2);
    CGFloat yIdeal = self.topImageView.center.y;
    
    return CGPointMake(xIdeal, yIdeal);
}

- (void)shuffleImages:(BOOL)animated newTopImage:(BOOL)newTopImage {
    _animating = YES;
    
    if (newTopImage) {
        [UIView animateWithDuration:animated?kShuffleAnimationDuration:0 animations:^{
            
            self.topImageView.center = [self bestAnimationPoint];
            
        } completion:^(BOOL finished) {
            
            [UIView animateWithDuration:animated?kShuffleAnimationDuration:0 animations:^{
                
                self.topImageView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
                [self sendSubviewToBack:self.topImageView];
                
            } completion:^(BOOL finished) {
                
                NSMutableArray *temp = [self.imageViews mutableCopy];
                [temp removeObjectAtIndex:0];
                [temp addObject:self.imageViews[0]];
                self.imageViews = temp;
                self.topImageView = self.imageViews[0];
                
                _animating = NO;
                
            }];
            
        }];
    } else {
        [UIView animateWithDuration:animated?kShuffleAnimationDuration:0 animations:^{
            self.topImageView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
        } completion:^(BOOL finished) {
            _animating = NO;
        }];
    }
}


#pragma mark - setters/getters

- (void)setDataSource:(id<LDImageStackDataSource>)dataSource {
    if (_dataSource != dataSource) {
        _dataSource = dataSource;
        
        [self initialiseWithNewDataSource];
    }
}


#pragma mark - user interaction

- (void)dragImage:(UIPanGestureRecognizer *)recognizer {
    CGPoint imagePosition = self.topImageView.center;
    
    if (_dragging) {
        CGPoint translation = [recognizer translationInView:self];
        
        imagePosition.x += translation.x;
        imagePosition.y += translation.y;
        
        self.topImageView.center = imagePosition;
        
        [recognizer setTranslation:CGPointZero inView:self];
    } else {
        BOOL isInsideLimit = CGRectContainsPoint(self.limitRect, imagePosition);
        [self shuffleImages:YES newTopImage:!isInsideLimit];
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    if (_animating) return;
    
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            _dragging = YES;
            [self dragImage:recognizer];
            break;
            
        case UIGestureRecognizerStateChanged:
            [self dragImage:recognizer];
            break;
            
        case UIGestureRecognizerStateEnded:
            _dragging = NO;
            [self dragImage:recognizer];
            break;
            
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            [self dragImage:recognizer];
            _dragging = NO;
            break;
            
        default:
            break;
    }
}


@end
