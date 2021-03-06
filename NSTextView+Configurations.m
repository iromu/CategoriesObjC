
NSSize const unlimitedSize = {FLT_MAX, FLT_MAX} ;

@implementation NSTextView (Configurations)

- (void)configureScrollingHorizontal:(BOOL)horizontal
							vertical:(BOOL)vertical {
	[self setHorizontallyResizable:horizontal] ;
	[self setVerticallyResizable:vertical] ;
    [self setAutoresizingMask:NSViewNotSizable] ;
    NSTextContainer *textContainer = [self textContainer] ;
	[textContainer setContainerSize:unlimitedSize] ;
    [textContainer setWidthTracksTextView:!horizontal] ;
    [textContainer setHeightTracksTextView:!vertical] ;
    NSSize contentSize = [[self enclosingScrollView] contentSize] ;
	[self setMinSize:contentSize] ;
    NSSize size ;
	size.width = horizontal ? FLT_MAX : contentSize.width ;
	if (vertical) {
		size.width -= [[[self enclosingScrollView] verticalScroller] frame].size.height ;
	}
	size.height = vertical ? FLT_MAX : contentSize.height ;
	if (horizontal) {
		size.height -= [[[self enclosingScrollView] horizontalScroller] frame].size.height ;
	}
	[self setMaxSize:size] ;
}	

@end
