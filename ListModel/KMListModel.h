//
//  KMListModel.h
//  ListModel
//
//  Created by Shawn on 2019/3/13.
//  Copyright © 2019 Shawn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <KMBaseModel.h>

@protocol KMListModelDataHandle <NSObject>

- (NSArray *)dataList;

@optional

- (void)addItem:(KMBaseModel *)item;

- (void)insertItem:(KMBaseModel *)item atIndex:(NSInteger)index;

- (void)removeItem:(KMBaseModel *)item;

- (void)removeItems:(NSArray *)items;

- (void)removeItemAtRange:(NSRange)range;

- (void)removeAllItems;

- (void)replaceItem:(KMBaseModel *)item atIndex:(NSInteger)index;

- (void)replaceItems:(NSArray *)items range:(NSRange)range;

- (void)replaceAllItems:(NSArray *)items;

@end

@protocol KMListDataPage <NSObject>

@optional

@property (nonatomic, readonly) BOOL pageEnable;

@property (nonatomic, readonly) NSInteger currentPage;

@property (nonatomic, readonly) NSInteger countOfPage;

@property (nonatomic, readonly) NSInteger totalPage;

@property (nonatomic, readonly) BOOL isLastPage;

@end

@protocol KMListModelDataRequest <NSObject>

@property (nonatomic, readonly, copy) NSString *requestPath;

@property (nonatomic, readonly) BOOL requestIsGet;

@property (nonatomic, readonly) BOOL isLoading;

- (void)refreshWithCompletion:(KMRequestCompletion)completion;

- (void)cancel;

@optional

- (NSDictionary *)paramter;

- (NSDictionary *)pageParameterWithPage:(NSInteger)page;

- (BOOL)loadMoreWithCompletion:(KMRequestCompletion)completion;

@end

@protocol KMListModelDataParser <NSObject>

@optional

- (Class)subModelClass;

- (NSArray *)dictionaryArrayForResponse:(id)response;

- (void)requestFinishWithResult:(id)result forRequestPage:(NSInteger)page;

- (KMBaseModel *)parseJsonDictionary:(NSDictionary *)jsonDictionary;

@end
