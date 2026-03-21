package funkin.android;

#if android
import com.player03.android6.Permissions as AndroidPermissions;
#end

final class PermissionType
{
	public static inline var ACCEPT_HANDOVER:String = "android.permission.ACCEPT_HANDOVER";
	public static inline var ACCESS_BACKGROUND_LOCATION:String = "android.permission.ACCESS_BACKGROUND_LOCATION";
	public static inline var ACCESS_COARSE_LOCATION:String = "android.permission.ACCESS_COARSE_LOCATION";
	public static inline var ACCESS_FINE_LOCATION:String = "android.permission.ACCESS_FINE_LOCATION";
	public static inline var ACCESS_MEDIA_LOCATION:String = "android.permission.ACCESS_MEDIA_LOCATION";
	public static inline var ACTIVITY_RECOGNITION:String = "android.permission.ACTIVITY_RECOGNITION";
	public static inline var ADD_VOICEMAIL:String = "com.android.voicemail.permission.ADD_VOICEMAIL";
	public static inline var ANSWER_PHONE_CALLS:String = "android.permission.ANSWER_PHONE_CALLS";
	public static inline var BLUETOOTH_ADVERTISE:String = "android.permission.BLUETOOTH_ADVERTISE";
	public static inline var BLUETOOTH_CONNECT:String = "android.permission.BLUETOOTH_CONNECT";
	public static inline var BLUETOOTH_SCAN:String = "android.permission.BLUETOOTH_SCAN";
	public static inline var BODY_SENSORS:String = "android.permission.BODY_SENSORS";
	public static inline var BODY_SENSORS_BACKGROUND:String = "android.permission.BODY_SENSORS_BACKGROUND";
	public static inline var CALL_PHONE:String = "android.permission.CALL_PHONE";
	public static inline var CAMERA:String = "android.permission.CAMERA";
	public static inline var GET_ACCOUNTS:String = "android.permission.GET_ACCOUNTS";
	public static inline var NEARBY_WIFI_DEVICES:String = "android.permission.NEARBY_WIFI_DEVICES";
	public static inline var POST_NOTIFICATIONS:String = "android.permission.POST_NOTIFICATIONS";
	public static inline var PROCESS_OUTGOING_CALLS:String = "android.permission.PROCESS_OUTGOING_CALLS";
	public static inline var READ_CALENDAR:String = "android.permission.READ_CALENDAR";
	public static inline var READ_CALL_LOG:String = "android.permission.READ_CALL_LOG";
	public static inline var READ_CONTACTS:String = "android.permission.READ_CONTACTS";
	public static inline var READ_EXTERNAL_STORAGE:String = "android.permission.READ_EXTERNAL_STORAGE";
	public static inline var READ_MEDIA_AUDIO:String = "android.permission.READ_MEDIA_AUDIO";
	public static inline var READ_MEDIA_IMAGES:String = "android.permission.READ_MEDIA_IMAGES";
	public static inline var READ_MEDIA_VIDEO:String = "android.permission.READ_MEDIA_VIDEO";
	public static inline var READ_PHONE_NUMBERS:String = "android.permission.READ_PHONE_NUMBERS";
	public static inline var READ_PHONE_STATE:String = "android.permission.READ_PHONE_STATE";
	public static inline var READ_SMS:String = "android.permission.READ_SMS";
	public static inline var RECEIVE_MMS:String = "android.permission.RECEIVE_MMS";
	public static inline var RECEIVE_SMS:String = "android.permission.RECEIVE_SMS";
	public static inline var RECEIVE_WAP_PUSH:String = "android.permission.RECEIVE_WAP_PUSH";
	public static inline var RECORD_AUDIO:String = "android.permission.RECORD_AUDIO";
	public static inline var SEND_SMS:String = "android.permission.SEND_SMS";
	public static inline var USE_SIP:String = "android.permission.USE_SIP";
	public static inline var UWB_RANGING:String = "android.permission.UWB_RANGING";
	public static inline var WRITE_CALENDAR:String = "android.permission.WRITE_CALENDAR";
	public static inline var WRITE_CALL_LOG:String = "android.permission.WRITE_CALL_LOG";
	public static inline var WRITE_CONTACTS:String = "android.permission.WRITE_CONTACTS";
	public static inline var WRITE_EXTERNAL_STORAGE:String = "android.permission.WRITE_EXTERNAL_STORAGE";
}

class Permissions
{
	public static function has(permission:PermissionType):Bool
	{
		#if android
		return AndroidPermissions.hasPermission(permission);
		#else
		return true;
		#end
	}

	public static function hasOrRequest(permission:PermissionType, cb:Bool->Void):Void
	{
		#if android
		if (AndroidPermissions.hasPermission(permission))
		{
			cb(true);
			return;
		}

		AndroidPermissions.requestPermission(permission);

		var listener = null;
		listener = function(perms:Array<String>)
		{
			AndroidPermissions.onPermissionsGranted.remove(listener);
			cb(perms.indexOf(permission) >= 0);
		}

		AndroidPermissions.onPermissionsGranted.add(listener);
		#else
		cb(true);
		#end
	}

	public static function hasOrRequestMany(perms:Array<PermissionType>, cb:Bool->Void):Void
	{
		#if android
		var allGranted = true;

		for (p in perms)
		{
			if (!AndroidPermissions.hasPermission(p))
			{
				allGranted = false;
				break;
			}
		}

		if (allGranted)
		{
			cb(true);
			return;
		}

		AndroidPermissions.requestPermissions(perms);

		var listener = null;
		listener = function(granted:Array<String>)
		{
			AndroidPermissions.onPermissionsGranted.remove(listener);

			var ok = true;
			for (p in perms)
			{
				if (granted.indexOf(p) < 0)
				{
					ok = false;
					break;
				}
			}

			cb(ok);
		}

		AndroidPermissions.onPermissionsGranted.add(listener);
		#else
		cb(true);
		#end
	}
}
