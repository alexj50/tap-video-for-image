//
//  ReviewCollectionCell.h
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

#import <UIKit/UIKit.h>

@interface ReviewCollectionCell : UICollectionViewCell
@property (strong, nonatomic) IBOutlet UILabel *pressDiscription;
@property (strong, nonatomic) IBOutlet UIImageView *cellImage;
@end
