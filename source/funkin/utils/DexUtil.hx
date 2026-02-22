package funkin.utils;

#if cpp
import cpp.Lib;
#end

class DexUtil
{
	#if (windows && cpp)
	@:cppFileCode('
        #include <windows.h>
    ')
	@:cppFunctionCode('
        const wchar_t* wpath = (const wchar_t*)String(path).wc_str();
        SystemParametersInfoW(
            SPI_SETDESKWALLPAPER,
            0,
            (PVOID)wpath,
            SPIF_UPDATEINIFILE | SPIF_SENDCHANGE
        );
    ')
	public static function changeWallpaper(path:String):Void
	{
	}
	#else
	public static function changeWallpaper(path:String):Void
	{
		trace("Wallpaper change only supported on Windows cpp target.");
	}
	#end
}
