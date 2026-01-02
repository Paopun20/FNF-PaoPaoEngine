package funkin.winapi;

#if (windows)
@:cppFileCode('
#include <stdlib.h>
#include <stdio.h>
#include <windows.h>
#include <winuser.h>
#include <dwmapi.h>
#include <strsafe.h>
#include <shellapi.h>
#include <iostream>
#include <string>

// Link the required libraries
#pragma comment(lib, "Shell32.lib")

// Function prototype for SetCurrentProcessExplicitAppUserModelID
extern "C" HRESULT WINAPI SetCurrentProcessExplicitAppUserModelID(PCWSTR AppID);

NOTIFYICONDATA m_NID;

// Constants for notification
const int NOTIFICATION_ID = 1001;
const wchar_t* APP_ID = L"com.psychengine.custommod";

// Set a custom AppUserModelID for the game process
void SetAppID() {
    HRESULT hr = SetCurrentProcessExplicitAppUserModelID(APP_ID);
    if (FAILED(hr)) {
        std::cerr << "Error: Failed to set AppUserModelID." << std::endl;
    }
}

// Initialize NOTIFYICONDATA structure
void InitNotifyIconData(HWND hWnd) {
    memset(&m_NID, 0, sizeof(m_NID));
    m_NID.cbSize = sizeof(NOTIFYICONDATA);
    m_NID.hWnd = hWnd;
    m_NID.uID = NOTIFICATION_ID;
    m_NID.uFlags = NIF_MESSAGE | NIF_INFO | NIF_TIP;
    m_NID.uCallbackMessage = WM_USER + 1;
    m_NID.dwInfoFlags = NIIF_INFO;
    m_NID.uVersion = NOTIFYICON_VERSION_4;
    StringCchCopy(m_NID.szTip, sizeof(m_NID.szTip) / sizeof(TCHAR), TEXT("Psych Engine Notification"));
}

// Convert std::string to std::wstring
std::wstring StringToWString(const std::string& str) {
    if (str.empty()) return std::wstring();
    int size_needed = MultiByteToWideChar(CP_UTF8, 0, &str[0], (int)str.size(), NULL, 0);
    std::wstring wstrTo(size_needed, 0);
    MultiByteToWideChar(CP_UTF8, 0, &str[0], (int)str.size(), &wstrTo[0], size_needed);
    return wstrTo;
}

// Show the notification
bool ShowNotification(const std::string& title, const std::string& desc) {
    SetAppID(); // Ensure the custom AppUserModelID is set
    
    HWND hWnd = GetForegroundWindow(); // Use the current game window
    InitNotifyIconData(hWnd);
    
    // Convert strings to wide strings for Windows API
    std::wstring wTitle = StringToWString(title);
    std::wstring wDesc = StringToWString(desc);
    
    // Copy the strings (using wchar_t versions)
    StringCchCopyW(m_NID.szInfoTitle, ARRAYSIZE(m_NID.szInfoTitle), wTitle.c_str());
    StringCchCopyW(m_NID.szInfo, ARRAYSIZE(m_NID.szInfo), wDesc.c_str());
    
    if (!Shell_NotifyIcon(NIM_ADD, &m_NID)) {
        std::cerr << "Error: Failed to add notification icon." << std::endl;
        return false;
    }
    
    // Modify the notification
    if (!Shell_NotifyIcon(NIM_MODIFY, &m_NID)) {
        std::cerr << "Error: Failed to modify notification." << std::endl;
        Shell_NotifyIcon(NIM_DELETE, &m_NID);
        return false;
    }
    
    // Clean up after showing the notification
    return Shell_NotifyIcon(NIM_DELETE, &m_NID);
}
')
class ToastNotification
{
	/**
	 * Show a Windows toast notification using native C++ Shell_NotifyIcon API
	 * @param title The notification title
	 * @param message The notification message body
	 * @return Bool indicating success or failure
	 */
	@:functionCode('
		return ShowNotification(title.c_str(), message.c_str());
	')
	public static function show(title:String, message:String):Bool {
		return false;
	}
}
#else
class ToastNotification
{
	public static function show(title:String, message:String):Bool {
		return false;
	}
}
#end