//
//  LDViewStack.m
//  View Stack
//
//  Created by Lee Daffen on 03/05/2013.
//  Copyright (c) 2013 Lee Daffen. All rights reserved.
//

#import "LDViewStack.h"
#import "LDViewStackView.h"

@interface LDViewStack() <UIGestureRecognizerDelegate>

@property (nonatomic, assign) NSUInteger countOfItems;
@property (nonatomic, strong) NSMutableArray *views;

@property (nonatomic, strong) LDViewStackView *topView;
@property (nonatomic, assign) CGRect limitRect;

@property (nonatomic, strong) UIPanGestureRecognizer *pan;

@end


@implementation LDViewStack {
    BOOL _dragging;
    BOOL _animating;
}

- (void)initialise {
    self.userInteractionEnabled = YES;
    
    self.limitRect = CGRectInset(self.bounds, self.bounds.size.width*0.2f, self.bounds.size.height*0.2f);
    
    self.pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    self.pan.delegate = self;
    [self addGestureRecognizer:self.pan];
    
    self.allowX = YES;
    self.allowY = YES;
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

- (UIView *)viewAtIndex:(NSUInteger)index {
    UIView *displayView = [self.dataSource viewStack:self viewAtIndex:index];
    
    // make a new empty view
    LDViewStackView *view = [[LDViewStackView alloc] initWithFrame:displayView.bounds];
    view.displayView = displayView;
    
    return view;
}

- (void)loadDataFromDataSource {
    self.countOfItems = [self.dataSource numberOfViewsInStack];
    self.views = [NSMutableArray arrayWithCapacity:self.countOfItems];
    
    for (int index=0; index<self.countOfItems ; ++index) {
        UIView *view = [self viewAtIndex:index];

        [self.views insertObject:view atIndex:0];
        [self addSubview:view];
    }
    
    if (self.views.count >= 1) {
        self.topView = self.views[0];
        if ([self.delegate respondsToSelector:@selector(viewStack:didMoveViewToTopOfStack:)])
            [self.delegate viewStack:self didMoveViewToTopOfStack:self.topView.displayView];
    }
}

- (void)initialiseWithNewDataSource {
    if (nil != self.views) {
        [self.views makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self.views removeAllObjects];
    }
    
    [self loadDataFromDataSource];
}

- (void)reloadData {
    [self loadDataFromDataSource];
}

- (CGPoint)bestAnimationPoint {
    CGPoint currentPoint = self.topView.center;
    CGFloat viewWidth = self.topView.bounds.size.width;
    
    CGFloat xIdeal = (currentPoint.x <= self.bounds.size.width/2) ? 0-(viewWidth/2) : self.bounds.size.width+(viewWidth/2);
    CGFloat yIdeal = self.topView.center.y;
    
    return CGPointMake(xIdeal, yIdeal);
}

- (void)shuffleViewsAnimated:(BOOL)animated newTopView:(BOOL)newTopView {
    _animating = YES;
    
    if (newTopView) {
        [UIView animateWithDuration:animated?self.shuffleAnimationDuration:0 animations:^{
            
            self.topView.center = [self bestAnimationPoint];
            
        } completion:^(BOOL finished) {
            
            [UIView animateWithDuration:animated?self.shuffleAnimationDuration:0 animations:^{
                
                self.topView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
                [self sendSubviewToBack:self.topView];
                
            } completion:^(BOOL finished) {
                
                NSMutableArray *temp = [self.views mutableCopy];
                [temp removeObjectAtIndex:0];
                [temp addObject:self.views[0]];
                self.views = temp;
                self.topView = self.views[0];
                
                if ([self.delegate respondsToSelector:@selector(viewStack:didMoveViewToTopOfStack:)])
                    [self.delegate viewStack:self didMoveViewToTopOfStack:self.topView.displayView];
                
                _animating = NO;
                
            }];
            
        }];
    } else {
        [UIView animateWithDuration:animated?self.shuffleAnimationDuration:0 animations:^{
            self.topView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
        } completion:^(BOOL finished) {
            _animating = NO;
        }];
    }
}


#pragma mark - setters/getters

- (void)setDataSource:(id<LDViewStackDataSource>)dataSource {
    if (_dataSource != dataSource) {
        _dataSource = dataSource;
        
        [self initialiseWithNewDataSource];
    }
}

- (CGFloat)shuffleAnimationDuration {
    if (0 == _shuffleAnimationDuration)
        _shuffleAnimationDuration = 0.15f;
    return _shuffleAnimationDuration;
}


#pragma mark - user interaction

- (void)dragView:(UIPanGestureRecognizer *)recognizer {
    CGPoint viewPosition = self.topView.center;
    
    if (_dragging) {        
        CGPoint translation = [recognizer translationInView:self];
        
        viewPosition.x += translation.x;
        viewPosition.y += translation.y;
        
        self.topView.center = viewPosition;
        
        [recognizer setTranslation:CGPointZero inView:self];
    } else {
        BOOL isInsideLimit = CGRectContainsPoint(self.limitRect, viewPosition);
        [self shuffleViewsAnimated:YES newTopView:!isInsideLimit];
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)recognizer {
    if (NO == [recognizer isMemberOfClass:[UIPanGestureRecognizer class]]) return YES;
    CGPoint translation = [(UIPanGestureRecognizer *)recognizer translationInView:self];
    
    if (NO == self.allowX)
        return fabs(translation.y) > fabs(translation.x);
        
    if (NO == self.allowY)
        return fabs(translation.x) > fabs(translation.y);
    
    return YES;
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    if (_animating) return;
    if (self.countOfItems < 2) return;
    
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            _dragging = YES;
            [self dragView:recognizer];
            break;
            
        case UIGestureRecognizerStateChanged:
            [self dragView:recognizer];
            break;
            
        case UIGestureRecognizerStateEnded:
            _dragging = NO;
            [self dragView:recognizer];
            break;
            
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            [self dragView:recognizer];
            _dragging = NO;
            break;
            
        default:
            break;
    }
}


@end
