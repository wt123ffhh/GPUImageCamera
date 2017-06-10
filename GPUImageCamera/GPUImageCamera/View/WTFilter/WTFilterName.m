//
//  WTFilterName.m
//  MagicPhoto
//
//  Created by 吴桐 on 16/2/26.
//  Copyright © 2016年 charmer. All rights reserved.
//

#import "WTFilterName.h"

@implementation WTFilterName


+ (NSString *)filterNameWith:(NSInteger)num {
    NSString *textStr = @"";
    switch (num) {
        case 0:
            textStr = @"NORMAL";
            break;
        case 1:
            textStr = @"MILK";
            break;
        case 2:
            textStr = @"VANILLA";
            break;
        case 3:
            textStr = @"MANGO";
            break;
        case 4:
            textStr = @"MATCHA";
            break;
        case 5:
            textStr = @"BLUEBERRY";
            break;
            
        case 11:
            textStr = @"VIENNA";
            break;
        case 12:
            textStr = @"PARIS";
            break;
        case 13:
            textStr = @"VENICE";
            break;
        case 14:
            textStr = @"ATHENS";
            break;
            
        case 6:
            textStr = @"KIWI";
            break;
        case 7:
            textStr = @"LEMON";
            break;
        case 8:
            textStr = @"GRAPE";
            break;
        case 9:
            textStr = @"BANANA";
            break;
        case 10:
            textStr = @"CHERRY";
            break;
            
        case 15:
            textStr = @"SPRING";
            break;
        case 16:
            textStr = @"SUMMER";
            break;
        case 17:
            textStr = @"AUTUMN";
            break;
        case 18:
            textStr = @"WINTER";
            break;
            
        case 19:
            textStr = @"FREE";
            break;
        case 20:
            textStr = @"MISS";
            break;
        case 21:
            textStr = @"HOPE";
            break;
        case 22:
            textStr = @"HAPPY";
            break;
        case 23:
            textStr = @"RETRO";
            break;
        case 24:
            textStr = @"SWEET";
            break;
            
//        case 25:
//            textStr = @"SUN";
//            break;
        case 25:
            textStr = @"SUN";
            break;
        case 26:
            textStr = @"GALAXY";
            break;
        case 27:
            textStr = @"MOON";
            break;
        case 28:
            textStr = @"AURORA";
            break;
        case 29:
            textStr = @"UNIVERSE";
            break;
            
        case 30:
            textStr = @"SEA";
            break;
        case 31:
            textStr = @"LIGHTEN";
            break;
        case 32:
            textStr = @"FOREST";
            break;
//        case 34:
//            textStr = @"WIND";
//            break;
        case 33:
            textStr = @"DREAM";
            break;
        case 34:
            textStr = @"SNOW";
            break;
            
        case 35:
            textStr = @"1978";
            break;
        case 36:
            textStr = @"ALONE";
            break;
        case 37:
            textStr = @"SILENCE";
            break;
        case 38:
            textStr = @"ONCE";
            break;
        case 39:
            textStr = @"MISS";
            break;
        case 40:
            textStr = @"PATIENT";
            break;
            
        default:
            break;
    }
    
    return textStr;
}

@end
