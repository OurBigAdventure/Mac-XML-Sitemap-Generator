//
//  OBASitemapData.h
//  Sitemap
//
//  Created by Chris Brown on 2/8/13.
//  Copyright (c) 2013 Chris Brown. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OBASitemapData : NSObject

@property (strong) NSString *URL;
@property (assign) float rating;
@property (assign) NSInteger numLinks;

- (id)initWithURL:(NSString*)URL rating:(float)rating numLinks:(NSInteger)numLinks;

@end
