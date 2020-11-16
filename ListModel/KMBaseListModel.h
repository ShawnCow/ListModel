//
//  KMBaseListModel.h
//  ListModel
//
//  Created by Shawn on 2019/3/13.
//  Copyright © 2019 Shawn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KMListModel.h"

@interface KMBaseListModel : KMBaseModel<KMListDataPage,KMListModelDataHandle,KMListModelDataParser,KMListModelDataRequest>

- (void)markPageInfoWithResult:(id)result currentRequestPageArray:(NSArray *)array requestPage:(NSInteger)page;

@end
