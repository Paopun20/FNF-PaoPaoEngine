package funkin.network;

import haxe.Http;
import haxe.Json;
import haxe.ds.StringMap;

class HttpClient
{
	public static final DEFAULT_TIMEOUT:Int = 10000;
	public static final MAX_RETRIES:Int = 3;

	public static function hasInternet(callback:Bool->Void):Void
	{
		sendRequest("https://www.google.com", null, function(success, _)
		{
			callback(success);
		});
	}

	public static function getRequest(url:String, callback:(Bool, Dynamic) -> Void, headers:StringMap<String> = null, queryParams:StringMap<String> = null):Void
	{
		sendRequest(url, null, callback, false, headers, 0, "GET", queryParams);
	}

	public static function postRequest(url:String, data:Dynamic, callback:(Bool, Dynamic) -> Void, headers:StringMap<String> = null,
			queryParams:StringMap<String> = null, contentType:String = "application/json"):Void
	{
		sendRequest(url, data, callback, true, headers, 0, "POST", queryParams, contentType);
	}

	public static function putRequest(url:String, data:Dynamic, callback:(Bool, Dynamic) -> Void, headers:StringMap<String> = null,
			queryParams:StringMap<String> = null, contentType:String = "application/json"):Void
	{
		sendRequest(url, data, callback, true, headers, 0, "PUT", queryParams, contentType);
	}

	public static function deleteRequest(url:String, callback:(Bool, Dynamic) -> Void, headers:StringMap<String> = null,
			queryParams:StringMap<String> = null):Void
	{
		sendRequest(url, null, callback, false, headers, 0, "DELETE", queryParams);
	}

	public static function patchRequest(url:String, data:Dynamic, callback:(Bool, Dynamic) -> Void, headers:StringMap<String> = null,
			queryParams:StringMap<String> = null, contentType:String = "application/json"):Void
	{
		sendRequest(url, data, callback, true, headers, 0, "PATCH", queryParams, contentType);
	}

	private static function sendRequest(url:String, data:Dynamic, callback:(Bool, Dynamic) -> Void, hasPayload:Bool = false, headers:StringMap<String> = null,
			retries:Int = 0, method:String = "GET", queryParams:StringMap<String> = null, contentType:String = "application/json"):Void
	{
		if (retries > MAX_RETRIES)
		{
			logError("Max retries exceeded", url, retries);
			safeCallback(callback, false, "Max retries exceeded");
			return;
		}

		final parsedUrl = validateUrl(url);
		if (parsedUrl == null)
		{
			logError("Invalid URL", url);
			safeCallback(callback, false, "Invalid URL");
			return;
		}

		final fullUrl = buildFullUrl(parsedUrl, queryParams);
		final http = new Http(fullUrl);
		http.cnxTimeout = DEFAULT_TIMEOUT;

		setHeaders(http, headers);

		// Apply HTTP method - use customRequest for non-GET/POST methods
		if (method != "GET" && method != "POST")
		{
			#if js
			http.customRequest(method != "POST", method);
			#else
			http.setHeader("X-HTTP-Method-Override", method);
			#end
		}

		if (hasPayload || method != "GET")
		{
			preparePayloadRequest(http, data, method, contentType);
		}

		var statusCode = 0;
		http.onStatus = status ->
		{
			statusCode = status;
		};
		http.onData = response ->
		{
			if (statusCode >= 400)
			{
				handleError('HTTP $statusCode', url, retries, () ->
				{
					sendRequest(url, data, callback, hasPayload, headers, retries + 1, method, queryParams, contentType);
				}, callback);
			}
			else
			{
				httptrace('$method Status: $statusCode');
				if (statusCode >= 300 && statusCode < 400)
				{
					final location = http.responseHeaders.get("Location");
					if (location != null)
					{
						CoolLog.debug('Redirecting to $location');
						sendRequest(location, data, callback, hasPayload, headers, retries + 1, method, queryParams, contentType);
					}
				}
				else if (statusCode >= 200 && statusCode < 300)
				{
					handleSuccess(response, callback);
				}
			}
		};
		http.onError = error -> handleError(error, url, retries, () ->
		{
			sendRequest(url, data, callback, hasPayload, headers, retries + 1, method, queryParams, contentType);
		}, callback);

		// Determine if this is a POST request
		final isPost = (method == "POST" || method == "PUT" || method == "PATCH");
		http.request(isPost);
	}

	private static function preparePayloadRequest(http:Http, data:Dynamic, method:String, contentType:String):Void
	{
		http.setHeader("Content-Type", contentType);
		if (data != null)
		{
			if (contentType == "application/json")
			{
				http.setPostData(Json.stringify(data));
			}
			else if (Std.isOfType(data, String))
			{
				http.setPostData(cast(data, String));
			}
			else
			{
				http.setPostData(Std.string(data));
			}
		}
		httptrace('Sending $method request with data: ${data != null ? Json.stringify(data) : "null"}');
	}

	private static function buildFullUrl(baseUrl:String, queryParams:StringMap<String>):String
	{
		if (queryParams == null)
			return baseUrl;
		return baseUrl + "?" + [
			for (key in queryParams.keys())
				'$key=${StringTools.urlEncode(queryParams.get(key))}'
		].join("&");
	}

	private static function setHeaders(http:Http, headers:StringMap<String>):Void
	{
		if (headers == null)
			return;
		for (key in headers.keys())
		{
			http.setHeader(key, headers.get(key));
		}
	}

	private static function handleSuccess(response:String, callback:(Bool, Dynamic) -> Void):Void
	{
		if (callback == null)
		{
			httptrace("Warning: Callback is null, skipping execution");
			return;
		}

		httptrace("Response received: " + response);
		safeCallback(callback, true, response);
	}

	private static function handleError(error:String, url:String, retries:Int, retryCallback:Void->Void, callback:(Bool, Dynamic) -> Void):Void
	{
		final errorType = categorizeError(error);
		logError(errorType, url, retries);

		if (shouldRetry(errorType))
		{
			httptrace('Retrying... Attempt ${retries + 1}');
			retryCallback();
		}
		else
		{
			safeCallback(callback, false, 'http error ($errorType): $error');
		}
	}

	private static function safeCallback(callback:(Bool, Dynamic) -> Void, success:Bool, result:Dynamic):Void
	{
		try
		{
			if (callback != null)
				callback(success, result);
		}
		catch (e:Dynamic)
		{
			httptrace("Callback execution failed: " + e);
		}
	}

	private static function categorizeError(error:String):String
	{
		return switch error
		{
			case error if (error.indexOf("Timeout") != -1): "Timeout Error";
			case error if (error.indexOf("Connection refused") != -1): "Connection Refused";
			case error if (error.indexOf("Invalid URL") != -1): "Invalid URL";
			case error if (error.indexOf("Failed to connect") != -1): "Failed to Connect";
			case error if (error.indexOf("Bad Request") != -1): "Bad Request";
			case error if (error.indexOf("Unauthorized") != -1): "Unauthorized";
			case error if (error.indexOf("Forbidden") != -1): "Forbidden";
			case error if (error.indexOf("Not Found") != -1): "Not Found";
			case error if (error.indexOf("Internal Server Error") != -1): "Internal Server Error";
			case error if (error.indexOf("Service Unavailable") != -1): "Service Unavailable";
			case error if (error.indexOf("Network is unreachable") != -1): "Network Unreachable";
			case error if (error.indexOf("Host is down") != -1): "Host Down";
			case error if (error.indexOf("SSL") != -1): "SSL Error";
			case error if (error.indexOf("Too Many Requests") != -1): "Too Many Requests";
			case error if (error.indexOf("Request Entity Too Large") != -1): "Request Entity Too Large";
			case error if (error.indexOf("Unsupported Media Type") != -1): "Unsupported Media Type";
			case error if (error.indexOf("Not Implemented") != -1): "Not Implemented";
			case error if (error.indexOf("Gateway Timeout") != -1): "Gateway Timeout";
			case error if (error.indexOf("HTTP") != -1): "HTTP Error";
			case error if (error.indexOf("General") != -1): "General Error";
			case _: "Unknown Error";
		}
	}

	private static function shouldRetry(errorType:String):Bool
	{
		// Only retry transient network errors and server errors that might resolve
		final retryableErrors = [
			"Network Error",
			"Timeout Error",
			"General Error",
			"Service Unavailable",
			"Connection Refused",
			"Failed to Connect",
			"Network Unreachable",
			"Host Down",
			"Gateway Timeout",
			"Internal Server Error",
			"Too Many Requests"
		];
		return retryableErrors.contains(errorType);
	}

	private static function logError(error:String, url:String, retries:Int = 0):Void
	{
		CoolLog.error('Error occurred: $error | URL: $url | Retry: $retries');
	}

	private static function validateUrl(url:String):String
	{
		if (url == null || url.trim() == "")
			return null;
		final parsedUrl = new HttpUrl(url);
		return parsedUrl.valid ? parsedUrl.toString() : null;
	}

	private static function httptrace(msg:String):Void
	{
		CoolLog.info(msg);
	}
}

private class HttpUrl
{
	private static final URL_REGEX = ~/^(https?):\/\/([a-zA-Z0-9.-]+)(:[0-9]+)?(\/.*)?$/;

	public final url:String;
	public final valid:Bool;
	public final secure:Bool;
	public final host:String;
	public final port:Int;
	public final request:String;

	public function new(url:String)
	{
		this.url = url;
		this.valid = URL_REGEX.match(url);

		if (this.valid)
		{
			secure = URL_REGEX.matched(1) == "https";
			host = URL_REGEX.matched(2);
			port = parsePort(URL_REGEX.matched(3));
			request = URL_REGEX.matched(4) != null ? URL_REGEX.matched(4) : "/";
		}
		else
		{
			secure = false;
			host = "";
			port = 80;
			request = "/";
		}
	}

	private function parsePort(portStr:String):Int
	{
		return portStr != null ? Std.parseInt(portStr.substr(1)) : (secure ? 443 : 80);
	}

	public function toString():String
	{
		return url;
	}
}
