//
//  CollectionViewCell.h
//  tapVideoForPicture
//
//  Created by Jacobson on 2/23/15.
//  Copyright (c) 2015 Alex Jacobson. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *cellImage;
@property (weak, nonatomic) IBOutlet UIView *selectedView;
@end
