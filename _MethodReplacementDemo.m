#import <objc/runtime.h>
#import <Cocoa/Cocoa.h>
#import "SSYAlert.h"

#if 0
#warning * Doing Method Replacement for Debugging!!!!!!!!

/* 
 20100311
 
 The ReadMe.txt document in Apple's MethodReplacement "The trick is
 to define a category on the class whose method you want to replace."
 That this sentence is incorrect.  You do *not* need to define a category
 on the class whose method you want to replace.

 In fact, the first argument of class_getInstanceMethod() need *not* be self,
 and therefore you can replace any method in *any* class, even a private
 one that's unknown to the SDK, with any method in *any class*.

 Realization of this fact makes Method Replacement MUCH more useful than is
 stated in the ReadMe because often, when something goes wrong you want to
 debug, it's in an Apple private class, which you cannot create a category on.

 I've pasted in here some code posted to cocoa-dev by Gideon King, today,
 which demonstrates replacing a method in an Apple private class.
 
 Gideon King advises:  I should mention that I did get this caveat note from
 Greg Parker (Apple's "runtime wrangler"):
    "..you must be cautious about what your replacement method does.
     In particular, you must not use any of the class's ivars and you
     must not call [super something]. As long as you follow those, you
     can swap in a method from any class, or even a C function with a
     matching argument list."
 
 Scott Morrison <smorr@indev.ca> adds:
 
 You can access ivars
 
 just 
 #include "objc/objc-class.h"
 
 and then use
 static Ivar theIvar;  //create a static to cache the ivar information
 if (!theIvar) theIvar = class_getInstanceVariable([self class], "ivarName"); //look up the ivar information and cache it
 
 id aValue = object_getIvar(self, ivar);  	//get the ivar
 object_setIvar(self,ivar,value); 	 	//this is an assignment, you are responsible for memory management!
 
 There are a few gotchas if your ivar is not an NSObject .
 
 
 
 For sending a message to the super.   
 [super amessage] won't work because super is  compile and will referred not to the super of self, but the super of the class containing the swizzled in message
 
 However the runtime can come to the rescue again by looking up the real super of self and sending a message to it.
 
 objc_msgSendSuper(&(struct objc_super){self, class_getSuperclass([self class])},_cmd, ...)
 
 set up a macro
 #define SUPER(...)  objc_msgSendSuper(&(struct objc_super){self, class_getSuperclass([self class])},_cmd, ##__VA_ARGS__)
 
 and then 
 SUPER(my,argument,List);
 
 of course this is assuming you are getting a void or NSObject * reuturn, if a different return type, you have to change things up.
 
 Jean-Daniel Dupas <devlists@shadowlab.org> advises:

 Method exchange is dangerous because if the target class (NSConcreteNotification) does not override the target function (dealloc), you may exchange it's superclass dealloc method instead and may end up overriding a method in a base class.
 Use it with great care and avoid it in production code if possible.

 
 
*/

@interface MyNSCFArray : NSObject {
}

- (void)my_initWithObjects:(id*)objects
					 count:(unsigned)count ;

@end

@implementation MyNSCFArray

+ (void)load {
	NSLog(@"43243 %s", __PRETTY_FUNCTION__) ;
	Method originalMethod = class_getInstanceMethod(NSClassFromString(@"NSCFArray"), @selector(initWithObjects:count:));	
	Method replacedMethod = class_getInstanceMethod(self, @selector(my_initWithObjects:count:));
	IMP imp1 = method_getImplementation(originalMethod);
	IMP imp2 = method_getImplementation(replacedMethod);
	// Set the implementation of dealloc to mydealloc
	method_setImplementation(originalMethod, imp2);
	// Add a my_initWithObjects:count: method to the NSCFArray with the original implementation
	class_addMethod(NSClassFromString(@"NSCFArray"), @selector(my_initWithObjects:count:), imp1, NULL);
}

- (void)my_initWithObjects:(id*)objects
					 count:(unsigned)count {
	if (count > 0) {
		NSAssert1(
				  objects[0] != nil,
				  @"Attempt to init array with %d objects and first one is nil",
				  count) ;
	}
	
	// Call the original method, whose implementation was exchanged with our own.
	// Note:  this ISN'T a recursive call.
	[self my_initWithObjects:objects
					   count:count];
}

@end

#endif



#if	0
#warning * Replacement of -[NSCFString appendString:] to log, crash sted raise if nil arg.

@interface DebugDaNSCFString : NSObject
@end

@implementation DebugDaNSCFString

+ (void)load {
	// Swap the implementations of one method with another.
	// When the message Xxx is sent to the object (either instance or class),
	// replacement_Xxx will be invoked instead.  Conversely,
	// replacement_Xxx will invoke Xxx.
	
	// NOTE: Below, use class_getInstanceMethod or class_getClassMethod as appropriate!!
	Method originalMethod = class_getInstanceMethod(NSClassFromString(@"NSCFString"), @selector(appendString:)) ;
	Method replacedMethod = class_getInstanceMethod(self, @selector(replacement_appendString:)) ;
	IMP imp1 = method_getImplementation(originalMethod);
	IMP imp2 = method_getImplementation(replacedMethod);
	// Set the implementation of appendString: to replacement_appendString:
	method_setImplementation(originalMethod, imp2);
	// Add a replacement_appendString: method to the NSCFString with the implementation as per the old dealloc method
	class_addMethod(NSClassFromString(@"NSCFString"), @selector(replacement_appendString:), imp1, NULL);
	NSLog(@"Replaced -[NSCFString appendString:]") ;
}

- (void)replacement_appendString:(NSString*)string {
	if (string) {
		// Due to the swap, this calls the original method
		[self replacement_appendString:string] ;
	}
	else {
		NSString* logger = [NSString stringWithFormat:@"Attempted to append nil to '%@'", self] ;
		NSLog(@"%@", logger) ;
		NSString* path = [NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"] ;
		NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970] ;
		NSString* filename = [NSString stringWithFormat:@"Message-from-BookMacster-%f.txt", timeInterval] ;
		path = [path stringByAppendingPathComponent:filename] ;
		NSError* error = nil ;
		BOOL ok = [logger writeToFile:path
				 atomically:NO
				   encoding:NSUTF8StringEncoding
					  error:&error] ;
		if (!ok) {
			[SSYAlert alertError:error] ;
		}
			
		// Crash!
		NSInteger* killer_p = 0x0 ;
		*killer_p = 0 ;
	}
}

@end

#endif



#if 0
#warning * Doing Method Replacement for Debugging!!!!!!!!
/* Now, here's one done in a category */

@interface NSTextView (DebugByReplacingMethod)
@end

@implementation NSTextView (DebugByReplacingMethod)

+ (void)load {
	// Swap the implementations of one method with another.
	// When the message Xxx is sent to the object (either instance or class),
	// replacement_Xxx will be invoked instead.  Conversely,
	// replacement_Xxx will invoke Xxx.
	
	// NOTE: Below, use class_getInstanceMethod or class_getClassMethod as appropriate!!
	NSLog(@"Replacing methods in %@", [self class]) ;
	Method originalMethod = class_getInstanceMethod(self, @selector(insertText:replacementRange:)) ;
	Method replacedMethod = class_getInstanceMethod(self, @selector(replacement_insertText:replacementRange:)) ;
	method_exchangeImplementations(originalMethod, replacedMethod) ;
}

- (id)replacement_insertText:(id)value
			replacementRange:(NSRange)range {
	NSLog(@"931: self = %@  frame: %@", self, NSStringFromRect([self frame])) ;
	NSLog(@"989:    value: %@  range: %@", value, NSStringFromRange(range)) ;
	
	// Due to the swap, this calls the original method
	return [self replacement_insertText:value
					   replacementRange:range] ;
}

@end

#endif

#if 0
#warning * Doing Method Replacement for Debugging!!!!!!!!

@interface NSValueBinder : NSObject {
}
@end

@interface NSValueBinder (DebugByReplacingMethod)
@end

@implementation NSValueBinder (DebugByReplacingMethod)

+ (void)load {
	// Swap the implementations of one method with another.
	// When the message Xxx is sent to the object (either instance or class),
	// replacement_Xxx will be invoked instead.  Conversely,
	// replacement_Xxx will invoke Xxx.
	
	// NOTE: Below, use class_getInstanceMethod or class_getClassMethod as appropriate!!
	NSLog(@"Replacing methods in %@", [self class]) ;
	Method originalMethod = class_getInstanceMethod(self, @selector(setValue:forBinding:error:)) ;
	Method replacedMethod = class_getInstanceMethod(self, @selector(replacement_setValue:forBinding:error:)) ;
	method_exchangeImplementations(originalMethod, replacedMethod) ;
}

- (id)replacement_setValue:(id)value
				forBinding:binding
error:(NSError**)error {
	NSLog(@"989: Setting value: %@", [value shortDescription]) ;
	NSLog(@"1062:    for binding: %@", binding) ;

	// Due to the swap, this calls the original method
	return [self replacement_setValue:(id)value
						   forBinding:binding
								error:(NSError**)error] ;
}

@end

#endif

#if 0
#warning * Doing Method Replacement for Debugging!!!!!!!!

@interface NSObject (DebugByReplacingMethod)
@end

@implementation NSObject (DebugByReplacingMethod)

+ (void)load {
	// Swap the implementations of one method with another.
	// When the message Xxx is sent to the object (either instance or class),
	// replacement_Xxx will be invoked instead.  Conversely,
	// replacement_Xxx will invoke Xxx.
	
	// NOTE: Below, use class_getInstanceMethod or class_getClassMethod as appropriate!!
	NSLog(@"Replacing methods in %@", [self class]) ;
	Method originalMethod = class_getInstanceMethod(self, @selector(bind:toObject:withKeyPath:options:)) ;
	Method replacedMethod = class_getInstanceMethod(self, @selector(replacement_bind:toObject:withKeyPath:options:)) ;
	method_exchangeImplementations(originalMethod, replacedMethod) ;
}

- (id)replacement_bind:binding
			  toObject:object
		   withKeyPath:keyPath
			   options:options {
	NSLog(@"binding: %@ to: %@ keyPath: %@ opts: %@", binding, [object shortDescription], keyPath, options) ;
	
	// Due to the swap, this calls the original method
	return [self replacement_bind:binding
						 toObject:object
					  withKeyPath:keyPath
						  options:options] ;
}

@end

#endif


#if 0
#warning * Doing Method Replacement for Debugging!!!!!!!!
/* Now, here's one done in a category.  Do this to log a backtrace when a managed object is deleted */

@interface NSManagedObjectContext (DebugByReplacingMethod)
@end

@implementation NSManagedObjectContext (DebugByReplacingMethod)

+ (void)load {
	// Swap the implementations of one method with another.
	// When the message Xxx is sent to the object (either instance or class),
	// replacement_Xxx will be invoked instead.  Conversely,
	// replacement_Xxx will invoke Xxx.
	
	// NOTE: Below, use class_getInstanceMethod or class_getClassMethod as appropriate!!
	NSLog(@"Replacing methods in %@", [self class]) ;
	Method originalMethod = class_getInstanceMethod(self, @selector(deleteObject:)) ;
	Method replacedMethod = class_getInstanceMethod(self, @selector(replacement_deleteObject:)) ;
	method_exchangeImplementations(originalMethod, replacedMethod) ;
}

- (id)replacement_deleteObject:(id)object {
	if ([[object className] isEqualToString:@"Trigger"]) {
		NSLog(@"93114: Deleting trigger: %@ Backtrace: %@", [object shortDescription], SSYDebugBacktrace()) ;
	}
	
	// Due to the swap, this calls the original method
	return [self replacement_deleteObject:object] ;
}

@end

#endif

