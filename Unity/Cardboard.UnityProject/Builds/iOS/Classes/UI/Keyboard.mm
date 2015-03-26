#include "Keyboard.h"
#include "DisplayManager.h"
#include "iPhone_Common.h"
#include <string>


static KeyboardDelegate*	_keyboard = nil;

static bool					_shouldHideInput = false;
static bool					_shouldHideInputChanged = false;

extern "C" float UnityDeviceDPI();

@implementation KeyboardDelegate
{
	UITextView*		textView;
	UITextField*	textField;
	
	UIView*			inputView; // Input field: textView for multiline, textField for single line
	UIView*			editView;  // Stuff not part of the actual keyboard: textView for multiline, fieldToolbar for single line

	UIToolbar*      viewToolbar;
	UIToolbar*      fieldToolbar;
	CGRect			_area;
	
	NSString*		initialText;
	
	UIKeyboardType	keyboardType;
	BOOL			multiline;
	
	BOOL			rotating;
	
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
	_canceled = YES;
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
	
	if (editView)
		editView.hidden = YES;
	
	_active = NO;
}

- (void)keyboardDidChangeFrame:(NSNotification*)notification;
{
	_active = true;
	
	CGRect srcRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	CGRect rect		= [UnityGetGLView() convertRect:srcRect fromView: nil];
	
	if( rect.origin.y >= [UnityGetGLView() bounds].size.height )
	{
		_active  = NO;
		
		if(editView)
			editView.hidden = YES;
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
		viewToolbar = [[UIToolbar alloc] initWithFrame :CGRectMake(0, 0, 0, 48)];

		textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
		[textView setDelegate: self];
		textView.font = [UIFont systemFontOfSize:18.0];
		textView.hidden = YES;
		// For multiline input show toolbar as part of the keyboard to avoid touches going through it
		textView.inputAccessoryView = viewToolbar;

		fieldToolbar = [[UIToolbar alloc] initWithFrame :CGRectMake(0, 0, 0, 0)];
		fieldToolbar.hidden = YES;
		UnitySetViewTouchProcessing(fieldToolbar, touchesIgnored);

		textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 0, 30)];
		[textField setDelegate: self];
		[textField setBorderStyle: UITextBorderStyleRoundedRect];
		textField.font = [UIFont systemFontOfSize:20.0];
		textField.clearButtonMode = UITextFieldViewModeWhileEditing;

		viewToolbar.items  = [[NSArray alloc] initWithObjects:
		    [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone target:self action:@selector(textInputDone:)],
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel target:self action:@selector(textInputCancel:)],
		    nil];

		fieldToolbar.items = [[NSArray alloc] initWithObjects:
		    [[UIBarButtonItem alloc] initWithCustomView:textField],
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone target:self action:@selector(textInputDone:)],
		    [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel target:self action:@selector(textInputCancel:)],
		    nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidChangeFrame:) name:UIKeyboardDidChangeFrameNotification object:nil];
	}
	
	return self;
}

- (void)showUI
{
	[UnityGetGLView() addSubview:editView];
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
		
		inputView = textView;
		editView = textView;
	}
	else
	{
		[textField setPlaceholder: [NSString stringWithUTF8String: param.placeholder]];
		[textField setText: initialText];
		[textField setKeyboardType: param.keyboardType];
		[textField setAutocorrectionType: param.autocorrectionType];
		[textField setSecureTextEntry: (BOOL)param.secure];
		[textField setKeyboardAppearance: param.appearance];
		
		inputView = textField;
		editView = fieldToolbar;
	}

	[self shouldHideInput:_shouldHideInput];
	
	_done		= NO;
	_canceled	= NO;
	_active		= YES;
	
	[self performSelectorOnMainThread: @selector(showUI) withObject:nil waitUntilDone:NO];
}

- (void)hide
{
	[self keyboardWillHide:nil];
	[inputView resignFirstResponder];
	
	[editView retain];
	[editView removeFromSuperview];
	
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
	if (!rotating)
	{
		if (multiline)
			viewToolbar.hidden = _inputHidden ? YES : NO;
		editView.hidden = _inputHidden ? YES : NO;
	}
}

- (void)positionInput:(CGRect)kbRect x:(float)x y:(float)y
{
	static const unsigned kInputBarSize = 48;
	
	if (multiline)
	{
		// use smaller area for iphones and bigger one for ipads
		int height = UnityDeviceDPI() > 300 ? 75 : 100;
		
		textView.frame = CGRectMake(0, y - height,kbRect.size.width, height);
	}
	else
	{
		CGRect   statusFrame  = [UIApplication sharedApplication].statusBarFrame;
		unsigned statusHeight = statusFrame.size.height;
		
		fieldToolbar.frame	= CGRectMake(0, y - kInputBarSize - statusHeight, kbRect.size.width, kInputBarSize);
		textField.frame	= CGRectMake(inputView.frame.origin.x, inputView.frame.origin.y,
									 kbRect.size.width - 3*18 - 2*50, inputView.frame.size.height
									 );
	}
	
	_area = CGRectMake(x, y, kbRect.size.width, kbRect.size.height);
	[self updateInputHidden];
}

- (CGRect)queryArea
{
	return editView.hidden ? _area : CGRectUnion(_area, editView.frame);
}

+ (void)StartReorientation
{
	if(_keyboard && _keyboard.active)
		_keyboard->rotating = YES;
}

+ (void)FinishReorientation
{
	if(_keyboard && _keyboard.active)
	{
		_keyboard->rotating = NO;
		
		[_keyboard->inputView resignFirstResponder];
		[_keyboard->inputView becomeFirstResponder];
	}
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

@end



//==============================================================================
//
//  Unity Interface:

void UnityKeyboard_Show(unsigned keyboardType, bool autocorrection, bool multiline, bool secure, bool alert, const char* text, const char* placeholder)
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
		autocorrectionTypes[autocorrection ? 0 : 1],
		keyboardAppearances[alert ? 1 : 0],
		multiline, secure
	};
	
	[[KeyboardDelegate Instance] show:param];
}

void UnityKeyboard_Hide()
{
	// do not send hide if didnt create keyboard
	// TODO: probably assert?
	if(!_keyboard)
		return;
	
	[[KeyboardDelegate Instance] hide];
}

void UnityKeyboard_SetText(const char* text)
{
	[KeyboardDelegate Instance].text = [NSString stringWithUTF8String: text];
}

void UnityKeyboard_GetText(std::string* text)
{
	*text = [[KeyboardDelegate Instance].text UTF8String];
}

bool UnityKeyboard_IsActive()
{
	return _keyboard && _keyboard.active;
}

bool UnityKeyboard_IsDone()
{
	return _keyboard && _keyboard.done;
}

bool UnityKeyboard_WasCanceled()
{
	return _keyboard && _keyboard.canceled;
}

void UnityKeyboard_SetInputHidden(bool hidden)
{
	_shouldHideInput		= hidden;
	_shouldHideInputChanged	= true;
	
	// update hidden status only if keyboard is on screen to avoid showing input view out of nowhere
	if(_keyboard && _keyboard.active)
		[_keyboard updateInputHidden];
}

bool UnityKeyboard_IsInputHidden()
{
	return _shouldHideInput;
}

void UnityKeyboard_GetRect(float* x, float* y, float* w, float* h)
{
	CGRect area = _keyboard ? _keyboard.area : CGRectMake(0,0,0,0);
	
	// convert to unity coord system
	
	float	multX	= (float)GetMainRenderingSurface()->targetW / UnityGetGLView().bounds.size.width;
	float	multY	= (float)GetMainRenderingSurface()->targetH / UnityGetGLView().bounds.size.height;
	
	*x = 0;
	*y = area.origin.y * multY;
	*w = area.size.width * multX;
	*h = area.size.height * multY;
}
