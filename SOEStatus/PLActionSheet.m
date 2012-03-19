//
//  PLActionSheet.m
//  SOEStatus
//
//  Created by Paul Lynch on 14/03/2012.
//  Copyright (c) 2012 P & L Systems. All rights reserved.
//

#import "PLActionSheet.h"

@interface PLActionSheet ()

@property (nonatomic, copy) DismissBlock dismissBlock;
@property (nonatomic, copy) CancelBlock cancelBlock;
@property (nonatomic, retain) id view;

@end


@implementation PLActionSheet

@synthesize dismissBlock, cancelBlock, view;

+ (void)actionSheetWithTitle:(NSString *)title                     
      destructiveButtonTitle:(NSString *)destructiveButtonTitle
                     buttons:(NSArray *)buttonTitles
                    showFrom:(id)view
                   onDismiss:(DismissBlock)dismissed                   
                    onCancel:(CancelBlock)cancelled {
    [[[[self alloc] initWithTitle:title destructiveButtonTitle:destructiveButtonTitle buttons:buttonTitles showFrom:view onDismiss:dismissed onCancel:cancelled] autorelease] show];
}

- (id)initWithTitle:(NSString *)title                     
destructiveButtonTitle:(NSString *)destructiveButtonTitle
            buttons:(NSArray *)buttonTitles
           showFrom:(id)aView
          onDismiss:(DismissBlock)dismissed                   
           onCancel:(CancelBlock)cancelled {
    [self initWithTitle:title delegate:self cancelButtonTitle:nil destructiveButtonTitle:destructiveButtonTitle otherButtonTitles:nil];
    
    for (NSString *thisButtonTitle in buttonTitles)
        [self addButtonWithTitle:thisButtonTitle];
    
    [self addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
    self.cancelButtonIndex = [buttonTitles count];
    
    if (destructiveButtonTitle)
        self.cancelButtonIndex ++;
    
    self.dismissBlock = dismissed;
    self.cancelBlock = cancelled;
    self.view = aView;
    
    return self;
}

- (void)dealloc {
    self.dismissBlock = nil;
    self.cancelBlock = nil;
    self.view = nil;
    [super dealloc];
}

- (void)show {
    if ([view isKindOfClass:[UITabBar class]])
        [self showFromTabBar:(UITabBar*) view];
    
    if ([view isKindOfClass:[UIView class]])
        [self showInView:view];
    
    if ([view isKindOfClass:[UIBarButtonItem class]])
        [self showFromBarButtonItem:(UIBarButtonItem*) view animated:YES];
}

#pragma UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if (buttonIndex == [actionSheet cancelButtonIndex]) {
		if (self.cancelBlock) self.cancelBlock();
	} else {
        if (self.dismissBlock) self.dismissBlock(buttonIndex);
    }
}

@end
