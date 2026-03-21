package funkin.android;

#if android
import com.player03.android6.Permissions as AndroidPermissions;
#end

class PermissionType
{
	public static var ACCEPT_HANDOVER = "android.permission.ACCEPT_HANDOVER";
	public static var ACCESS_BACKGROUND_LOCATION = "android.permission.ACCESS_BACKGROUND_LOCATION";
	public static var ACCESS_COARSE_LOCATION = "android.permission.ACCESS_COARSE_LOCATION";
	public static var ACCESS_FINE_LOCATION = "android.permission.ACCESS_FINE_LOCATION";
	public static var ACCESS_MEDIA_LOCATION = "android.permission.ACCESS_MEDIA_LOCATION";
	public static var ACTIVITY_RECOGNITION = "android.permission.ACTIVITY_RECOGNITION";
	public static var ADD_VOICEMAIL = "com.android.voicemail.permission.ADD_VOICEMAIL";
	public static var ANSWER_PHONE_CALLS = "android.permission.ANSWER_PHONE_CALLS";
	public static var BLUETOOTH_ADVERTISE = "android.permission.BLUETOOTH_ADVERTISE";
	public static var BLUETOOTH_CONNECT = "android.permission.BLUETOOTH_CONNECT";
	public static var BLUETOOTH_SCAN = "android.permission.BLUETOOTH_SCAN";
	public static var BODY_SENSORS = "android.permission.BODY_SENSORS";
	public static var BODY_SENSORS_BACKGROUND = "android.permission.BODY_SENSORS_BACKGROUND";
	public static var CALL_PHONE = "android.permission.CALL_PHONE";
	public static var CAMERA = "android.permission.CAMERA";
	public static var GET_ACCOUNTS = "android.permission.GET_ACCOUNTS";
	public static var NEARBY_WIFI_DEVICES = "android.permission.NEARBY_WIFI_DEVICES";
	public static var POST_NOTIFICATIONS = "android.permission.POST_NOTIFICATIONS";
	public static var PROCESS_OUTGOING_CALLS = "android.permission.PROCESS_OUTGOING_CALLS";
	public static var READ_CALENDAR = "android.permission.READ_CALENDAR";
	public static var READ_CALL_LOG = "android.permission.READ_CALL_LOG";
	public static var READ_CONTACTS = "android.permission.READ_CONTACTS";
	public static var READ_EXTERNAL_STORAGE = "android.permission.READ_EXTERNAL_STORAGE";
	public static var READ_MEDIA_AUDIO = "android.permission.READ_MEDIA_AUDIO";
	public static var READ_MEDIA_IMAGES = "android.permission.READ_MEDIA_IMAGES";
	public static var READ_MEDIA_VIDEO = "android.permission.READ_MEDIA_VIDEO";
	public static var READ_PHONE_NUMBERS = "android.permission.READ_PHONE_NUMBERS";
	public static var READ_PHONE_STATE = "android.permission.READ_PHONE_STATE";
	public static var READ_SMS = "android.permission.READ_SMS";
	public static var RECEIVE_MMS = "android.permission.RECEIVE_MMS";
	public static var RECEIVE_SMS = "android.permission.RECEIVE_SMS";
	public static var RECEIVE_WAP_PUSH = "android.permission.RECEIVE_WAP_PUSH";
	public static var RECORD_AUDIO = "android.permission.RECORD_AUDIO";
	public static var SEND_SMS = "android.permission.SEND_SMS";
	public static var USE_SIP = "android.permission.USE_SIP";
	public static var UWB_RANGING = "android.permission.UWB_RANGING";
	public static var WRITE_CALENDAR = "android.permission.WRITE_CALENDAR";
	public static var WRITE_CALL_LOG = "android.permission.WRITE_CALL_LOG";
	public static var WRITE_CONTACTS = "android.permission.WRITE_CONTACTS";
	public static var WRITE_EXTERNAL_STORAGE = "android.permission.WRITE_EXTERNAL_STORAGE";
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
