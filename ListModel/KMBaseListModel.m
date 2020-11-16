//
//  KMBaseListModel.m
//  ListModel
//
//  Created by Shawn on 2019/3/13.
//  Copyright © 2019 Shawn. All rights reserved.
//

#import "KMBaseListModel.h"
#import <XXHTTPRequest+RequestConfig.h>
#import <NSObject+RequestTaskManager.h>

@interface KMBaseListModel ()<XXJSONToModelHandle>
{
    NSMutableArray *dataSourceArray;
}

@end

@implementation KMBaseListModel

@synthesize currentPage,countOfPage,requestPath,pageEnable,isLastPage,isLoading;

- (instancetype)init
{
    self = [super init];
    if (self) {
        dataSourceArray = [NSMutableArray array];
        countOfPage = 20;
        currentPage = 0;
        pageEnable = NO;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    dataSourceArray = [NSMutableArray array];
}

#pragma mark - request

- (BOOL)requestIsGet
{
    return YES;
}

- (void)refreshWithCompletion:(KMRequestCompletion)completion
{
    [self _requestPage:1 completion:completion];
}

- (BOOL)loadMoreWithCompletion:(KMRequestCompletion)completion
{
    if (isLoading) {
        if (completion) {
            NSError *error = [NSError errorWithDomain:@"XXBaseListModelErrorDomain" code:9000 userInfo:@{NSLocalizedDescriptionKey:@"正在努力加载中..."}];
            completion(error);
        }
        return NO;
    }
    if (isLastPage) {
        if (completion) {
            NSError *error = [NSError errorWithDomain:@"XXBaseListModelErrorDomain" code:9001 userInfo:@{NSLocalizedDescriptionKey:@"最后一页啦"}];
            completion(error);
        }
        return NO;
    }
    if (self.pageEnable == NO) {
        if (completion) {
            NSError *error = [NSError errorWithDomain:@"XXBaseListModelErrorDomain" code:9002 userInfo:@{NSLocalizedDescriptionKey:@"不支持分页"}];
            completion(error);
        }
        return NO;
    }
    [self _requestPage:self.currentPage + 1 completion:completion];
    return YES;
}

- (void)_requestPage:(NSInteger)page completion:(KMRequestCompletion)completion
{
    [self cancel];
    if (self.requestPath == nil) {
#ifdef DEBUG
        [[NSException exceptionWithName:@"XXBaseListModel" reason:@"request path must override" userInfo:nil] raise];
#endif
    }
    
    XXHTTPRequest *request = nil;
    if (self.requestIsGet) {
        request = [XXHTTPRequest defaultGETHTTPRequest];
    }else
    {
        request = [XXHTTPRequest defaultPOSTHTTPRequest];
    }
    request.URLString = self.requestPath;
    NSMutableDictionary * tempDic = [NSMutableDictionary dictionary];
    if (self.pageEnable) {
        [tempDic addEntriesFromDictionary:[self pageParameterWithPage:page]];
    }
    if ([self respondsToSelector:@selector(paramter)]) {
        NSDictionary *tempParameter = self.paramter;
        if (tempParameter) {
            [tempDic addEntriesFromDictionary:tempParameter];
        }
    }
    request.parameter = tempDic;
    if ([self respondsToSelector:@selector(parseJsonDictionary:)]) {
        request.responseORMHandle = self;
    }
    if ([self respondsToSelector:@selector(subModelClass)]) {
        request.responseORMTargetModelClass = self.subModelClass;
    }
    
    __weak KMBaseListModel *ws = self;
    NSURLSessionTask *task = (NSURLSessionTask *)[request sendRequestWithCompletion:^(NSError *error, id result) {
        [ws _requestFinishWithResponseError:error result:result page:page completion:completion];
    }];
    [self xx_addTask:task key:@"list"];
    isLoading = YES;
}

- (void)_requestFinishWithResponseError:(NSError *)error result:(id)result page:(NSInteger)page completion:(KMRequestCompletion)completion
{
     isLoading = NO;
    
    if (error) {
        if (completion) {
            completion(error);
        }
    }else
    {
        NSArray *tempArray = nil;
        if ([result isKindOfClass:[KMBaseModel class]]) {
            tempArray = [self dictionaryArrayForResponse:result];
        }else if ([result isKindOfClass:[NSArray class]]) {
            tempArray = result;
        }
        if (tempArray) {
            if (page == 1) {
                @synchronized (dataSourceArray) {
                    [dataSourceArray removeAllObjects];
                    [dataSourceArray addObjectsFromArray:tempArray];
                }
            }else
            {
                @synchronized (dataSourceArray) {
                    [dataSourceArray addObjectsFromArray:tempArray];
                }
            }
            currentPage = page;
            [self markPageInfoWithResult:result currentRequestPageArray:tempArray requestPage:page];
        }
        if ([self respondsToSelector:@selector(requestFinishWithResult:forRequestPage:)]) {        
            [self requestFinishWithResult:result forRequestPage:page];
        }
        if (completion) {
            completion(nil);
        }
    }
}

- (void)markPageInfoWithResult:(id)result currentRequestPageArray:(NSArray *)array requestPage:(NSInteger)page
{
    if (self.pageEnable) {
        if ([array count] < self.countOfPage) {
            isLastPage = YES;
        }else
        {
            isLastPage = NO;
        }
    }
}

- (void)cancel
{
    id<XXRequestTaskOpration> task = [self xx_TaskForKey:@"list"];
    [task cancel];
    isLoading = NO;
}

- (id)xx_modelFromJSONDictionary:(NSDictionary *)jsonDic
{
    return [self parseJsonDictionary:jsonDic];
}

#pragma mark - handle delegate

- (NSArray *)dataList
{
    @synchronized (dataSourceArray) {
        NSArray *dataList = [dataSourceArray copy];
        return dataList;
    }
}

- (void)addItem:(KMBaseModel *)item
{
    if (item == nil) {
        return;
    }
    @synchronized (dataSourceArray) {
        [dataSourceArray addObject:item];
    }
}

- (void)insertItem:(KMBaseModel *)item atIndex:(NSInteger)index
{
    if (item == nil) {
        return;
    }
    @synchronized (dataSourceArray) {
        [dataSourceArray insertObject:item atIndex:index];
    }
}

- (void)removeItem:(KMBaseModel *)item
{
    if (item == nil) {
        return;
    }
    @synchronized (dataSourceArray) {
        [dataSourceArray removeObject:item];
    }
}

- (void)removeItems:(NSArray *)items
{
    if (items.count == 0) {
        return;
    }
    items = [items copy];
    @synchronized (dataSourceArray) {
        [dataSourceArray addObjectsFromArray:items];
    }
}

- (void)removeItemAtRange:(NSRange)range
{
    if (range.length == 0) {
        return;
    }
    @synchronized (dataSourceArray) {
        [dataSourceArray removeObjectsInRange:range];
    }
}

- (void)removeAllItems
{
    @synchronized (dataSourceArray) {
        [dataSourceArray removeAllObjects];
    }
}

- (void)replaceItem:(KMBaseModel *)item atIndex:(NSInteger)index
{
    if (item == nil) {
        return;
    }
    @synchronized (dataSourceArray) {
        [dataSourceArray replaceObjectAtIndex:index withObject:item];
    }
}

- (void)replaceItems:(NSArray *)items range:(NSRange)range
{
    @synchronized (dataSourceArray) {
        [dataSourceArray replaceObjectsInRange:range withObjectsFromArray:items];
    }
}

- (void)replaceAllItems:(NSArray *)items
{
    if (items == nil) {
        return;
    }
    @synchronized (dataSourceArray) {
        [dataSourceArray removeAllObjects];
        [dataSourceArray addObjectsFromArray:items];
    }
}
@end
