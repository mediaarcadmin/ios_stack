//
//  THCache.m
//  libEucalyptus
//
//  Created by James Montgomerie on 30/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "THCache.h"
#import "THLog.h"

#import <search.h>

@implementation THCache

- (id)init
{
    if((self = [super init])) {
        pthread_mutex_init(&_cacheMutex, NULL);
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(_didReceiveMemoryWarning)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:[UIApplication sharedApplication]];        
    }
    return self;
}

- (void)dealloc
{    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidReceiveMemoryWarningNotification
                                                  object:[UIApplication sharedApplication]];

    [self flushCache:YES];
    NSParameterAssert(_cacheTree == NULL);

    pthread_mutex_destroy(&_cacheMutex);
    
    [super dealloc];
}

typedef struct TreeItem {
    void *key;
    void *value;
    THCache *self;
} TreeItem;

- (NSComparisonResult)compareItem:(const void *)item1 toItem:(const void *)item2
{
    return [(id)((TreeItem *)item1)->key compare:(id)((TreeItem *)item2)->key];
}

- (void)freeItem:(TreeItem *)item
{
    [(id)item->key release];
    [(id)item->value release];
    free(item);
}

static int CompareKeys(const void *arg1, const void *arg2)
{
    return [((TreeItem *)arg1)->self compareItem:arg1 toItem:arg2];
}

static void Accumulate(const void *pNode, const VISIT which, const int depth)
{
    if(which == preorder || which == leaf) {
        TreeItem *item = *((TreeItem **)pNode);
        item->self->_deletionAccumulator[item->self->_deletionAccumulatorCount] = item;
        ++item->self->_deletionAccumulatorCount;
    }
}

- (void)flushCache:(BOOL)force
{
    pthread_mutex_lock(&_cacheMutex);
    _deletionAccumulator = malloc(sizeof(TreeItem *) * _count);
    twalk(_cacheTree, Accumulate);
    
    for(size_t i = 0; i < _deletionAccumulatorCount; ++i) {
        TreeItem *item = _deletionAccumulator[i];
        if(force || [(id)item->value retainCount] == 1) {
            tdelete(item, &_cacheTree, CompareKeys);
            [self freeItem:item];
            --_count;
        }
    }
    
    free(_deletionAccumulator);
    _deletionAccumulator = nil;
    _deletionAccumulatorCount = 0;
    
    pthread_mutex_unlock(&_cacheMutex);    
}

- (void)_didReceiveMemoryWarning
{
    THLog(@"Cache had %ld items - emptying...", (long)_count);

    [self flushCache:NO];
    
    THLog(@"Cache has %ld items.", (long)_count);
}


- (void)cacheObject:(id)value forKey:(id)key
{    
    pthread_mutex_lock(&_cacheMutex);
    TreeItem *item = malloc(sizeof(TreeItem));
    item->key = [key retain];
    item->value = [value retain];
    item->self = self; 
    
    TreeItem **pItemInTree = tsearch(item, &_cacheTree, CompareKeys);
    if(pItemInTree) {
        TreeItem *itemInTree = *pItemInTree;
        if(itemInTree != item) {
            if(itemInTree->key != item->key) {
                [(id)itemInTree->key release];
                itemInTree->key = item->key;
            }
            if(itemInTree->value != item->value) {
                [(id)itemInTree->value release];
                itemInTree->value = item->value;
            }
            free(item);
        } else {
            ++_count;
        }
    }
    
    pthread_mutex_unlock(&_cacheMutex);
}

- (id)objectForKey:(id)key
{
    id ret;
    
    TreeItem findItem;
    findItem.key = key;
    findItem.self = self;
    
    pthread_mutex_lock(&_cacheMutex);
    TreeItem **item = tfind(&findItem, &_cacheTree, CompareKeys);
    if(item) {
        ret = [[(id)(*item)->value retain] autorelease];
    } else {
        ret = nil;
    }
    pthread_mutex_unlock(&_cacheMutex);
    return ret;
}

@end


@implementation THIntegerKeyedCache

- (NSComparisonResult)compareItem:(const void *)item1 toItem:(const void *)item2
{
    return (intptr_t)((TreeItem *)item1)->key - (intptr_t)((TreeItem *)item2)->key;
}

- (void)freeItem:(TreeItem *)item
{
    [(id)item->value release];
    free(item);
}

- (void)cacheObject:(id)value forKey:(uint32_t)key
{    
    pthread_mutex_lock(&_cacheMutex);

    TreeItem *item = malloc(sizeof(TreeItem));
    item->key = (void *)((intptr_t)(key));
    item->value = [value retain];
    item->self = self; 
    
    TreeItem **pItemInTree = tsearch(item, &_cacheTree, CompareKeys);
    if(pItemInTree) {
        TreeItem *itemInTree = *pItemInTree;
        if(itemInTree != item) {
            if(itemInTree->key != item->key) {
                itemInTree->key = item->key;
            }
            if(itemInTree->value != item->value) {
                [(id)itemInTree->value release];
                itemInTree->value = item->value;
            }
            free(item);
        } else {
            ++_count;
        }
    }    
    
    pthread_mutex_unlock(&_cacheMutex);
}

- (id)objectForKey:(uint32_t)key
{
    id ret;
        
    TreeItem findItem;
    findItem.key = (void *)((intptr_t)key);
    findItem.self = self;

    pthread_mutex_lock(&_cacheMutex);
    TreeItem **item = tfind(&findItem, &_cacheTree, CompareKeys);
    if(item) {
        ret = [[(id)(*item)->value retain] autorelease];
    } else {
        ret = nil;
    }
    pthread_mutex_unlock(&_cacheMutex);
    return ret;
}

@end
