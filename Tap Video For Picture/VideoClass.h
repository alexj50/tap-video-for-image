//
//  VideoClass.h
//  tapVideoForPicture
//
//  Created by Jacobson on 2/24/15.
//  Copyright (c) 2015 Alex Jacobson. All rights reserved.
//
//  Software written for the expressed purpose of evaluating
//  Alex Jacobson's software programing skills.
//
//  Any commercial use of this software without the expressed written
//  concent of Alex Jacobson is strictly forbidden
//
// contact: ajacobson50@gmial.com

#import <Foundation/Foundation.h>

@interface VideoClass : NSObject
@property NSURL *url;
@property NSData *imageData;
@property BOOL selected;
@end
