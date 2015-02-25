//
//  CustomSegue.m
//  Tap Video For Picture
//
//  Created by Jacobson on 2/25/15.
//  Copyright (c) 2015 Alex Jacobson. All rights reserved.
//
//  Software written for the expressed purpose of evaluating
//  Alex Jacobson's software programing skills.
//
//  Any commercial use of this software without the expressed written
//  concent of Alex Jacobson is strictly forbidden
//
// contact: ajacobson50@gmial.com


#import "CustomSegue.h"

@implementation CustomSegue

- (void)perform {
    UIViewController* source = (UIViewController *)self.sourceViewController;
    UIViewController* destination = (UIViewController *)self.destinationViewController;
    
    CGRect sourceFrame = source.view.frame;
    sourceFrame.origin.x = -sourceFrame.size.width;
    
    CGRect destFrame = destination.view.frame;
    destFrame.origin.x = destination.view.frame.size.width;
    destination.view.frame = destFrame;
    
    destFrame.origin.x = 0;
    
    [source.view.superview addSubview:destination.view];
    
    [UIView animateWithDuration:0.4
                     animations:^{
                         source.view.frame = sourceFrame;
                         destination.view.frame = destFrame;
                     }
                     completion:^(BOOL finished) {
                         UIWindow *window = source.view.window;
                         [window setRootViewController:destination];
                     }];
}

@end
