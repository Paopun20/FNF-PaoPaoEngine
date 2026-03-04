package funkin.utils;

#if cpp
import cpp.Lib;
#end

enum abstract MessageBoxIcon(Int)
{
	var MSG_ERROR = 0x00000010;
	var MSG_QUESTION = 0x00000020;
	var MSG_WARNING = 0x00000030;
	var MSG_INFORMATION = 0x00000040;
}

/**
 * Utility class for various functions.
 * Windows-specific functions are included.
 */
#if DEXAPI_ALLOWED
@:buildXml('
 <compilerflag value="/DelayLoad:ComCtl32.dll"/>

 <target id="haxe">
     <lib name="dwmapi.lib" if="windows" />
     <lib name="shell32.lib" if="windows" />
     <lib name="gdi32.lib" if="windows" />
     <lib name="user32.lib" if="windows" />
     <lib name="psapi.lib" if="windows" />
 </target>
 ')
@:cppFileCode('
 #ifndef SCREENSHOT_CPP_INCLUDED
 #define SCREENSHOT_CPP_INCLUDED

 #include <Windows.h>
 #include <windowsx.h>
 #include <cstdio>
 #include <iostream>
 #include <tchar.h>
 #include <wingdi.h>
 #include <winuser.h>
 #include <dwmapi.h>
 #include <winternl.h>
 #include <Shlobj.h>
 #include <commctrl.h>
 #include <string>

 #include <chrono>
 #include <thread>
 #include <sysinfoapi.h>
 #include <psapi.h>

 #define UNICODE

 #pragma comment(lib, "Dwmapi")
 #pragma comment(lib, "ntdll.lib")
 #pragma comment(lib, "user32.lib")
 #pragma comment(lib, "Shell32.lib")
 #pragma comment(lib, "gdi32.lib")
 #pragma comment(lib, "psapi.lib")

 // This is so that all window-related functions ALWAYS apply to the engine window.
 static std::string globalWindowTitle = "Friday Night Funkin\': Plus Engine";

 // Get the active window handle
 static HWND GET_WINDOW() {
     return GetForegroundWindow();
 }

 // Get the engine window by title
 static HWND GET_ENGINE_WINDOW() {
	HWND hwnd = GetForegroundWindow();
     char windowTitle[256];

     GetWindowTextA(hwnd, windowTitle, sizeof(windowTitle));

     if (globalWindowTitle == windowTitle) {
         return hwnd;
     }

     return FindWindowA(NULL, globalWindowTitle.c_str());
 }

 //////////////////////////////////////////////////////////////////////////////////////////////////////

 static BOOL SaveToFile(HBITMAP hBitmap3, LPCTSTR lpszFileName)
 {
	HDC hDC;
	int iBits;
	WORD wBitCount;
	DWORD dwPaletteSize=0, dwBmBitsSize=0, dwDIBSize=0, dwWritten=0;
	BITMAP Bitmap0;
	BITMAPFILEHEADER bmfHdr;
	BITMAPINFOHEADER bi;
	LPBITMAPINFOHEADER lpbi;
	HANDLE fh, hDib, hPal,hOldPal2=NULL;
	hDC = CreateDC("DISPLAY", NULL, NULL, NULL);
	iBits = GetDeviceCaps(hDC, BITSPIXEL) * GetDeviceCaps(hDC, PLANES);
	DeleteDC(hDC);
	if (iBits <= 1)
		wBitCount = 1;
	else if (iBits <= 4)
		wBitCount = 4;
	else if (iBits <= 8)
		wBitCount = 8;
	else
		wBitCount = 24;
	GetObject(hBitmap3, sizeof(Bitmap0), (LPSTR)&Bitmap0);
	bi.biSize = sizeof(BITMAPINFOHEADER);
	bi.biWidth = Bitmap0.bmWidth;
	bi.biHeight =-Bitmap0.bmHeight;
	bi.biPlanes = 1;
	bi.biBitCount = wBitCount;
	bi.biCompression = BI_RGB;
	bi.biSizeImage = 0;
	bi.biXPelsPerMeter = 0;
	bi.biYPelsPerMeter = 0;
	bi.biClrImportant = 0;
	bi.biClrUsed = 256;
	dwBmBitsSize = ((Bitmap0.bmWidth * wBitCount +31) & ~31) /8
													* Bitmap0.bmHeight;
	hDib = GlobalAlloc(GHND,dwBmBitsSize + dwPaletteSize + sizeof(BITMAPINFOHEADER));
	lpbi = (LPBITMAPINFOHEADER)GlobalLock(hDib);
	*lpbi = bi;

	hPal = GetStockObject(DEFAULT_PALETTE);
	if (hPal)
	{
		hDC = GetDC(NULL);
		hOldPal2 = SelectPalette(hDC, (HPALETTE)hPal, FALSE);
		RealizePalette(hDC);
	}


	GetDIBits(hDC, hBitmap3, 0, (UINT) Bitmap0.bmHeight, (LPSTR)lpbi + sizeof(BITMAPINFOHEADER)
		+dwPaletteSize, (BITMAPINFO *)lpbi, DIB_RGB_COLORS);

	if (hOldPal2)
	{
		SelectPalette(hDC, (HPALETTE)hOldPal2, TRUE);
		RealizePalette(hDC);
		ReleaseDC(NULL, hDC);
	}

	fh = CreateFile(lpszFileName, GENERIC_WRITE,0, NULL, CREATE_ALWAYS,
		FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN, NULL);

	if (fh == INVALID_HANDLE_VALUE)
		return FALSE;

	bmfHdr.bfType = 0x4D42; // "BM"
	dwDIBSize = sizeof(BITMAPFILEHEADER) + sizeof(BITMAPINFOHEADER) + dwPaletteSize + dwBmBitsSize;
	bmfHdr.bfSize = dwDIBSize;
	bmfHdr.bfReserved1 = 0;
	bmfHdr.bfReserved2 = 0;
	bmfHdr.bfOffBits = (DWORD)sizeof(BITMAPFILEHEADER) + (DWORD)sizeof(BITMAPINFOHEADER) + dwPaletteSize;

	WriteFile(fh, (LPSTR)&bmfHdr, sizeof(BITMAPFILEHEADER), &dwWritten, NULL);

	WriteFile(fh, (LPSTR)lpbi, dwDIBSize, &dwWritten, NULL);
	GlobalUnlock(hDib);
	GlobalFree(hDib);
	CloseHandle(fh);

	return TRUE;
 }

 static int screenCapture(int x, int y, int w, int h, LPCSTR fname)
 {
     HDC hdcSource = GetDC(NULL);
     HDC hdcMemory = CreateCompatibleDC(hdcSource);

     int capX = GetDeviceCaps(hdcSource, HORZRES);
     int capY = GetDeviceCaps(hdcSource, VERTRES);

     HBITMAP hBitmap = CreateCompatibleBitmap(hdcSource, w, h);
     HBITMAP hBitmapOld = (HBITMAP)SelectObject(hdcMemory, hBitmap);

     BitBlt(hdcMemory, 0, 0, w, h, hdcSource, x, y, SRCCOPY);
     hBitmap = (HBITMAP)SelectObject(hdcMemory, hBitmapOld);

     DeleteDC(hdcSource);
     DeleteDC(hdcMemory);

     HPALETTE hpal = NULL;
     if(SaveToFile(hBitmap, fname)) return 1;
     return 0;
 }

 #endif // SCREENSHOT_CPP_INCLUDED
 ')
#end
class DexUtil
{
	#if DEXAPI_ALLOWED
	@:cppFunctionCode('
	const char* filepath = path;

	int uiAction = SPIF_UPDATEINIFILE | SPIF_SENDCHANGE;
	char filepathBuffer[MAX_PATH];
	strcpy_s(filepathBuffer, filepath);

	SystemParametersInfoA(SPI_SETDESKWALLPAPER, 0, filepathBuffer, uiAction);
    ')
	#end
	public static function changeWallpaper(path:String):Void
	{
	}

	/**
	 * Hides or shows desktop icons
	 * @param hide True to hide, false to show
	 */
	#if DEXAPI_ALLOWED
	@:functionCode('
		bool value = hide;
		HWND hProgman = FindWindowW (L"Progman", L"Program Manager");
		HWND hChild = GetWindow (hProgman, GW_CHILD);

		if (value == true) {
			ShowWindow (hChild, SW_HIDE);
		} else {
			ShowWindow (hChild, SW_SHOW);
		}
    ')
	#end
	public static function hideDesktopIcons(hide:Bool)
	{
	}

	/**
	 * Makes the window fully transparent (click-through)
	 * @param transparent True to enable transparency, false to disable
	 */
	#if DEXAPI_ALLOWED
	@:functionCode('
		HWND hwnd = GET_ENGINE_WINDOW();
		if (!hwnd) return;

		LONG_PTR exStyle = GetWindowLongPtr(hwnd, GWL_EXSTYLE);

		if (transparent) {
			// Enable layered window with transparency
			SetWindowLongPtr(hwnd, GWL_EXSTYLE, exStyle | WS_EX_LAYERED | WS_EX_TRANSPARENT);
			SetLayeredWindowAttributes(hwnd, RGB(0, 0, 0), 0, LWA_COLORKEY);
		} else {
			// Disable transparency
			SetWindowLongPtr(hwnd, GWL_EXSTYLE, exStyle & ~WS_EX_TRANSPARENT);
			SetLayeredWindowAttributes(hwnd, 0, 255, LWA_ALPHA);
		}
	')
	#end
	public static function setWindowTransparent(transparent:Bool):Void
	{
	}

	/**
	 * Shows or hides the main window
	 * @param show True to show, false to hide
	 */
	#if DEXAPI_ALLOWED
	@:functionCode('
		HWND hwnd = GET_ENGINE_WINDOW();
		if (show) {
			ShowWindow(hwnd, SW_SHOW);
		} else {
			ShowWindow(hwnd, SW_HIDE);
		}
    ')
	#end
	public static function setWindowVisible(show:Bool)
	{
	}

	/**
	 * Checks if the application is running with administrator privileges
	 * @return True if running as admin, false otherwise
	 */
	#if DEXAPI_ALLOWED
	@:functionCode('
		BOOL isAdmin = FALSE;
		SID_IDENTIFIER_AUTHORITY ntAuthority = SECURITY_NT_AUTHORITY;
		PSID adminGroup = nullptr;

		if (AllocateAndInitializeSid(&ntAuthority, 2,
			SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_ADMINS,
			0, 0, 0, 0, 0, 0, &adminGroup)) {

			if (!CheckTokenMembership(nullptr, adminGroup, &isAdmin)) {
				isAdmin = FALSE;
			}

			FreeSid(adminGroup);
		}

		return isAdmin == TRUE;
	')
	#end
	public static function isRunningAsAdmin():Bool
	{
		return false;
	}

	/**
	 * Sets the window as layered to enable transparency effects
	 * Must be called before using setWindowAlpha
	 */
	#if DEXAPI_ALLOWED
	@:functionCode('

		HWND window = GET_WINDOW();
		if (window) {
			SetWindowLong(window, GWL_EXSTYLE, GetWindowLong(window, GWL_EXSTYLE) ^ WS_EX_LAYERED);
		}
	')
	#end
	public static function setWindowLayered():Void
	{
	}

	#if DEXAPI_ALLOWED
	@:functionCode('
		HWND window = GET_WINDOW();
		if (window) {
			float a = alpha;

			if (alpha > 1) {
				a = 1;
			}
			if (alpha < 0) {
				a = 0;
			}

			SetLayeredWindowAttributes(window, 0, (255 * (a * 100)) / 100, LWA_ALPHA);
		}
	')
	#end
	public static function setWindowAlpha(alpha:Float):Void
	{
	}

	#if DEXAPI_ALLOWED
	@:functionCode('
		HWND hwnd = GET_WINDOW();

		DWORD exStyle = GetWindowLong(hwnd, GWL_EXSTYLE);
		BYTE alpha = 255;

		if (exStyle & WS_EX_LAYERED) {
			DWORD flags;
			GetLayeredWindowAttributes(hwnd, NULL, &alpha, &flags);
		}

		float alphaFloat = static_cast<float>(alpha) / 255.0f;

		return alphaFloat;
	')
	#end
	public static function getWindowAlpha():Float
	{
		return 1.0;
	}

	/**
	 * Sets the transparency of desktop icons
	 * @param alpha Alpha value from 0.0 (fully transparent) to 1.0 (fully opaque)
	 */
	#if DEXAPI_ALLOWED
	@:functionCode('
		HWND hProgman = FindWindowW(L"Progman", L"Program Manager");
		HWND hChild = GetWindow(hProgman, GW_CHILD);

		float a = alpha;
		if (alpha > 1) {
			a = 1;
		}
		if (alpha < 0) {
			a = 0;
		}

       	SetLayeredWindowAttributes(hChild, 0, (255 * (a * 100)) / 100, LWA_ALPHA);
    ')
	#end
	public static function setDesktopWindowsAlpha(alpha:Float)
	{
	}

	/**
	 * Sets the transparency of the taskbar
	 * @param alpha Alpha value from 0.0 (fully transparent) to 1.0 (fully opaque)
	 */
	#if DEXAPI_ALLOWED
	@:functionCode('
		HWND hwnd = FindWindowA("Shell_traywnd", nullptr);
		HWND hwnd2 = FindWindowA("Shell_SecondaryTrayWnd", nullptr);

		float a = alpha;
		if (alpha > 1) {
			a = 1;
		}
		if (alpha < 0) {
			a = 0;
		}

       	SetLayeredWindowAttributes(hwnd, 0, (255 * (a * 100)) / 100, LWA_ALPHA);
		SetLayeredWindowAttributes(hwnd2, 0, (255 * (a * 100)) / 100, LWA_ALPHA);
    ')
	#end
	public static function setTaskBarAlpha(alpha:Float)
	{
	}
}
