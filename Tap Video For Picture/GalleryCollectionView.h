//
//  GalleryCollectionView.h
//  tapVideoForPicture
//
//  Created by Jacobson on 2/23/15.
//  Copyright (c) 2015 Alex Jacobson. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GalleryCollectionView : UIViewController
@property (weak, nonatomic) IBOutlet UICollectionView *collection;
@property (strong,nonatomic) NSMutableArray *imageArray;
@end
