#include "Keyboard.h"
#include "DisplayManager.h"
#include "UnityForwardDecls.h"
#include <string>


NSString* const UIKeyboardWillChangeFrameNotification = @"UIKeyboardWillChangeFrameNotification";
NSString* const UIKeyboardDidChangeFrameNotification = @"UIKeyboardDidChangeFrameNotification";


static KeyboardDelegate*	_keyboard = nil;

static bool					_shouldHideInput = false;
static bool					_shouldHideInputChanged = false;

@implementation KeyboardDelegate
{
	UITextView*		textView;
	UITextField*	textField;

	UIView*			inputView;
	UIToolbar*		toolbar;
	CGRect			_area;

	NSArray*		viewToolbarItems;
	NSArray*		fieldToolbarItems;

	NSString*		initialText;

	UIKeyboardType	keyboardType;
	BOOL			multiline;

	BOOL			_inputHidden;
	BOOL			_active;
	BOOL			_done;
	BOOL			_canceled;
}

@synthesize area;
@synthesize active		= _active;
@synthesize done		= _done;
@synthesize canceled	= _canceled;
@synthesize text;

- (BOOL)textFieldShouldReturn:(UITextField*)textFieldObj
{
	[self hide];
	return YES;
}

- (void)textInputDone:(id)sender
{
	[self hide];
}

- (void)textInputCancel:(id)sender
{
	_canceled = true;
	[self hide];
}

- (void)keyboardDidShow:(NSNotification*)notification;
{
	if (notification.userInfo == nil || inputView == nil)
		return;

	CGRect srcRect	= [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	CGRect rect		= [UnityGetGLView() convertRect:srcRect fromView:nil];

	[self positionInput:rect x:rect.origin.x y:rect.origin.y];
	_active = YES;
}

- (void)keyboardWillHide:(NSNotification*)notification;
{
	_area = CGRectMake(0,0,0,0);

	if (inputView == nil)
		return;

	toolbar.hidden = YES;
	if(textView)
		textView.hidden = YES;

	_active = [self isInputViewStillEditing];
}

- (void)keyboardDidChangeFrame:(NSNotification*)notification;
{
	_active = true;

	CGRect srcRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	CGRect rect		= [UnityGetGLView() convertRect:srcRect fromView: nil];

	if( rect.origin.y >= [UnityGetGLView() bounds].size.height )
	{
		_active = [self isInputViewStillEditing];
		toolbar.hidden = YES;

		if(textView)
			textView.hidden = YES;
	}
	else
	{
		[self positionInput:rect x:rect.origin.x y:rect.origin.y];
	}
}

+ (void)Initialize
{
	NSAssert(_keyboard == nil, @"[KeyboardDelegate Initialize] called after creating keyboard");
	if(!_keyboard)
		_keyboard = [[KeyboardDelegate alloc] init];
}

+ (KeyboardDelegate*)Instance
{
	if(!_keyboard)
		_keyboard = [[KeyboardDelegate alloc] init];

	return _keyboard;
}

- (id)init
{
	NSAssert(_keyboard == nil, @"You can have only one instance of KeyboardDelegate");
	self = [super init];
	if(self)
	{
		textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 480, 480, 30)];
		[textView setDelegate: self];
		textView.font = [UIFont systemFontOfSize:18.0];
		textView.hidden = YES;

		textField = [[UITextField alloc] initWithFrame:CGRectMake(0,0,120,30)];
		[textField setDelegate: self];
		[textField setBorderStyle: UITextBorderStyleRoundedRect];
		textField.font = [UIFont systemFontOfSize:20.0];
		textField.clearButtonMode = UITextFieldViewModeWhileEditing;

		toolbar = [[UIToolbar alloc] initWithFrame :CGRectMake(0,160,320,64)];
		toolbar.hidden = YES;
		UnitySetViewTouchProcessing(toolbar, touchesIgnored);

		UIBarButtonItem* inputItem	= [[UIBarButtonItem alloc] initWithCustomView:textField];
		UIBarButtonItem* doneItem	= [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone target:self action:@selector(textInputDone:)];
		UIBarButtonItem* cancelItem	= [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel target:self action:@selector(textInputCancel:)];

		viewToolbarItems	= @[doneItem, cancelItem];
		fieldToolbarItems	= @[inputItem, doneItem, cancelItem];

		inputItem = nil;
		doneItem = nil;
		cancelItem = nil;

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidChangeFrame:) name:UIKeyboardDidChangeFrameNotification object:nil];
	}

	return self;
}

- (void)showUI
{
	[UnityGetGLView() addSubview:toolbar];
	if(multiline)
		[UnityGetGLView() addSubview:inputView];

	[inputView becomeFirstResponder];
}


- (void)show:(KeyboardShowParam)param
{
	if(_active)
		[self hide];

	initialText = param.text ? [[NSString alloc] initWithUTF8String: param.text] : @"";

	multiline = param.multiline;
	if(param.multiline)
	{
		[textView setText: initialText];
		[textView setKeyboardType: param.keyboardType];
		[textView setAutocorrectionType: param.autocorrectionType];
		[textView setSecureTextEntry: (BOOL)param.secure];
		[textView setKeyboardAppearance: param.appearance];
	}
	else
	{
		[textField setPlaceholder: [NSString stringWithUTF8String: param.placeholder]];
		[textField setText: initialText];
		[textField setKeyboardType: param.keyboardType];
		[textField setAutocorrectionType: param.autocorrectionType];
		[textField setSecureTextEntry: (BOOL)param.secure];
		[textField setKeyboardAppearance: param.appearance];
	}

	inputView = multiline ? textView : textField;
	toolbar.items = multiline ? viewToolbarItems : fieldToolbarItems;

	[self shouldHideInput:_shouldHideInput];
	// if we unhide everything now the input will be shown smaller then needed quickly (and resized later)
	// so unhide only when keyboard is shown
	toolbar.hidden = YES;

	_done		= NO;
	_canceled	= NO;
	_active		= YES;

	[self performSelectorOnMainThread: @selector(showUI) withObject:nil waitUntilDone:NO];
}

- (void)hide
{
	[self keyboardWillHide:nil];
	[inputView resignFirstResponder];

	if(multiline)
		[inputView removeFromSuperview];

	[toolbar removeFromSuperview];

	_done = YES;
}

- (void)updateInputHidden
{
	if(_shouldHideInputChanged)
	{
		[self shouldHideInput:_shouldHideInput];
		_shouldHideInputChanged = false;
	}

	textField.returnKeyType = _inputHidden ? UIReturnKeyDone : UIReturnKeyDefault;
	toolbar.hidden = _inputHidden ? YES : NO;
	inputView.hidden = _inputHidden ? YES : NO;
}

- (void)positionInput:(CGRect)kbRect x:(float)x y:(float)y
{
	static const unsigned kInputBarSize = 48;

	if (multiline)
	{
		// use smaller area for iphones and bigger one for ipads
		int height = UnityDeviceDPI() > 300 ? 75 : 100;

		toolbar.frame		= CGRectMake(0, y - kInputBarSize, kbRect.size.width, kInputBarSize);
		inputView.frame		= CGRectMake(0, y - kInputBarSize - height,kbRect.size.width, height);
	}
	else
	{
		CGRect   statusFrame	= [UIApplication sharedApplication].statusBarFrame;
		unsigned statusHeight	= statusFrame.size.height;

		toolbar.frame	= CGRectMake(0, y - kInputBarSize - statusHeight, kbRect.size.width, kInputBarSize);
		inputView.frame	= CGRectMake(inputView.frame.origin.x, inputView.frame.origin.y,
									 kbRect.size.width - 3*18 - 2*50, inputView.frame.size.height
									);
	}

	_area = CGRectMake(x, y, kbRect.size.width, kbRect.size.height);
	[self updateInputHidden];
}

- (CGRect)queryArea
{
	return toolbar.hidden ? _area : CGRectUnion(_area, toolbar.frame);
}

+ (void)StartReorientation
{
	[CATransaction begin];
	{
		if(_keyboard && _keyboard.active)
		{
			if( _keyboard->multiline )
				_keyboard->inputView.hidden = YES;

			_keyboard->toolbar.hidden = YES;
		}
	}
	[CATransaction commit];
}

+ (void)FinishReorientation
{
	[CATransaction begin];
	{
		if(_keyboard && _keyboard.active)
		{
			if( _keyboard->multiline )
				_keyboard->inputView.hidden = NO;

			_keyboard->toolbar.hidden = NO;

			[_keyboard->inputView resignFirstResponder];
			[_keyboard->inputView becomeFirstResponder];
		}
	}
	[CATransaction commit];
}

- (NSString*)getText
{
	if(_canceled)	return initialText;
	else			return multiline ? [textView text] : [textField text];
}

- (void) setTextWorkaround:(id<UITextInput>)textInput text:(NSString*)newText
{
	UITextPosition* begin = [textInput beginningOfDocument];
	UITextPosition* end = [textInput endOfDocument];
	UITextRange* allText = [textInput textRangeFromPosition:begin toPosition:end];
	[textInput setSelectedTextRange:allText];
	[textInput insertText:newText];
}

- (void)setText:(NSString*)newText
{
	// We can't use setText on iOS7 because it does not update the undo stack.
	// We still prefer setText on other iOSes, because an undo operation results
	// in a smaller selection shown on the UI
	if (_ios70orNewer && !_ios80orNewer)
		[self setTextWorkaround: (multiline ? textView : textField) text:newText];

	if (multiline)
		[textView setText:newText];
	else
		[textField setText:newText];
}

- (void)shouldHideInput:(BOOL)hide
{
	if(hide)
	{
		switch(keyboardType)
		{
			case UIKeyboardTypeDefault:                 hide = YES;	break;
			case UIKeyboardTypeASCIICapable:            hide = YES;	break;
			case UIKeyboardTypeNumbersAndPunctuation:   hide = YES;	break;
			case UIKeyboardTypeURL:                     hide = YES;	break;
			case UIKeyboardTypeNumberPad:               hide = NO;	break;
			case UIKeyboardTypePhonePad:                hide = NO;	break;
			case UIKeyboardTypeNamePhonePad:            hide = NO;	break;
			case UIKeyboardTypeEmailAddress:            hide = YES;	break;
			default:                                    hide = NO;	break;
		}
	}

	_inputHidden = hide;
}

// Case 665265: on Chinese/Japanese keyboards when opening the suggestions popup
// and scrolling the list, the keyboard will dismiss.
// The popup opening triggers a keyboard hide by the OS but the text field still
// remains in editing mode. Therefore Unity keyboard should remain active if the
// text field is still first responder.
- (BOOL)isInputViewStillEditing {
    return inputView.isFirstResponder;
}

@end



//==============================================================================
//
//  Unity Interface:

extern "C" void UnityKeyboard_Show(unsigned keyboardType, int autocorrection, int multiline, int secure, int alert, const char* text, const char* placeholder)
{
	static const UIKeyboardType keyboardTypes[] =
	{
		UIKeyboardTypeDefault,
		UIKeyboardTypeASCIICapable,
		UIKeyboardTypeNumbersAndPunctuation,
		UIKeyboardTypeURL,
		UIKeyboardTypeNumberPad,
		UIKeyboardTypePhonePad,
		UIKeyboardTypeNamePhonePad,
		UIKeyboardTypeEmailAddress,
	};

	static const UITextAutocorrectionType autocorrectionTypes[] =
	{
		UITextAutocorrectionTypeDefault,
		UITextAutocorrectionTypeNo,
	};

	static const UIKeyboardAppearance keyboardAppearances[] =
	{
		UIKeyboardAppearanceDefault,
		UIKeyboardAppearanceAlert,
	};

	KeyboardShowParam param =
	{
		text, placeholder,
		keyboardTypes[keyboardType],
		autocorrectionTypes[autocorrection],
		keyboardAppearances[alert],
		(BOOL)multiline, (BOOL)secure
	};

	[[KeyboardDelegate Instance] show:param];
}

extern "C" void UnityKeyboard_Hide()
{
	// do not send hide if didnt create keyboard
	// TODO: probably assert?
	if(!_keyboard)
		return;

	[[KeyboardDelegate Instance] hide];
}

extern "C" void UnityKeyboard_SetText(const char* text)
{
	[KeyboardDelegate Instance].text = [NSString stringWithUTF8String: text];
}

extern "C" NSString* UnityKeyboard_GetText()
{
	return [KeyboardDelegate Instance].text;
}

extern "C" int UnityKeyboard_IsActive()
{
	return (_keyboard && _keyboard.active) ? 1 : 0;
}

extern "C" int UnityKeyboard_IsDone()
{
	return (_keyboard && _keyboard.done) ? 1 : 0;
}

extern "C" int UnityKeyboard_WasCanceled()
{
	return (_keyboard && _keyboard.canceled) ? 1 : 0;
}

extern "C" void UnityKeyboard_SetInputHidden(int hidden)
{
	_shouldHideInput		= hidden;
	_shouldHideInputChanged	= true;

	// update hidden status only if keyboard is on screen to avoid showing input view out of nowhere
	if(_keyboard && _keyboard.active)
		[_keyboard updateInputHidden];
}

extern "C" int UnityKeyboard_IsInputHidden()
{
	return _shouldHideInput ? 1 : 0;
}

extern "C" void UnityKeyboard_GetRect(float* x, float* y, float* w, float* h)
{
	CGRect area = _keyboard ? _keyboard.area : CGRectMake(0,0,0,0);

	// convert to unity coord system

	float	multX	= (float)GetMainDisplaySurface()->targetW / UnityGetGLView().bounds.size.width;
	float	multY	= (float)GetMainDisplaySurface()->targetH / UnityGetGLView().bounds.size.height;

	*x = 0;
	*y = area.origin.y * multY;
	*w = area.size.width * multX;
	*h = area.size.height * multY;
}
