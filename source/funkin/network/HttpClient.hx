package funkin.network;

import haxe.Http;
import haxe.Json;
import haxe.ds.StringMap;

using StringTools;

class HttpClient
{
	/** Seconds before a connection attempt is abandoned. */
	public static final DEFAULT_TIMEOUT_SECONDS:Int = 10;

	/** Maximum number of retry attempts for transient errors. */
	public static final MAX_RETRIES:Int = 3;

	// HTTP status code boundaries
	static final HTTP_SUCCESS_MIN:Int = 200;
	static final HTTP_REDIRECT_MIN:Int = 300;
	static final HTTP_CLIENT_ERROR_MIN:Int = 400;

	/** Checks basic internet connectivity by probing a reliable external host. */
	public static function hasInternet(callback:Bool->Void):Void
	{
		getRequest("https://www.google.com", (success, _) -> callback(success));
	}

	/** Sends an HTTP GET request and delivers the raw response string to `callback`. */
	public static function getRequest(url:String, callback:(Bool, Dynamic) -> Void, headers:StringMap<String> = null, queryParams:StringMap<String> = null):Void
	{
		dispatchRequest({
			url: url,
			method: "GET",
			data: null,
			includesRequestBody: false,
			headers: headers,
			queryParams: queryParams,
			contentType: "application/json",
			retries: 0,
			callback: callback
		});
	}

	/** Sends an HTTP POST request with `data` serialised according to `contentType`. */
	public static function postRequest(url:String, data:Dynamic, callback:(Bool, Dynamic) -> Void, headers:StringMap<String> = null,
			queryParams:StringMap<String> = null, contentType:String = "application/json"):Void
	{
		dispatchRequest({
			url: url,
			method: "POST",
			data: data,
			includesRequestBody: true,
			headers: headers,
			queryParams: queryParams,
			contentType: contentType,
			retries: 0,
			callback: callback
		});
	}

	/** Sends an HTTP PUT request with `data` serialised according to `contentType`. */
	public static function putRequest(url:String, data:Dynamic, callback:(Bool, Dynamic) -> Void, headers:StringMap<String> = null,
			queryParams:StringMap<String> = null, contentType:String = "application/json"):Void
	{
		dispatchRequest({
			url: url,
			method: "PUT",
			data: data,
			includesRequestBody: true,
			headers: headers,
			queryParams: queryParams,
			contentType: contentType,
			retries: 0,
			callback: callback
		});
	}

	/** Sends an HTTP DELETE request. */
	public static function deleteRequest(url:String, callback:(Bool, Dynamic) -> Void, headers:StringMap<String> = null,
			queryParams:StringMap<String> = null):Void
	{
		dispatchRequest({
			url: url,
			method: "DELETE",
			data: null,
			includesRequestBody: false,
			headers: headers,
			queryParams: queryParams,
			contentType: "application/json",
			retries: 0,
			callback: callback
		});
	}

	/** Sends an HTTP PATCH request with `data` serialised according to `contentType`. */
	public static function patchRequest(url:String, data:Dynamic, callback:(Bool, Dynamic) -> Void, headers:StringMap<String> = null,
			queryParams:StringMap<String> = null, contentType:String = "application/json"):Void
	{
		dispatchRequest({
			url: url,
			method: "PATCH",
			data: data,
			includesRequestBody: true,
			headers: headers,
			queryParams: queryParams,
			contentType: contentType,
			retries: 0,
			callback: callback
		});
	}

	private static function dispatchRequest(req:RequestContext):Void
	{
		if (req.retries >= MAX_RETRIES)
		{
			logError("Max retries exceeded", req.url, req.retries);
			safeCallback(req.callback, false, "Max retries exceeded");
			return;
		}

		final validatedUrl = validateUrl(req.url);
		if (validatedUrl == null)
		{
			logError("Invalid URL", req.url);
			safeCallback(req.callback, false, "Invalid URL");
			return;
		}

		final http = buildHttpRequest(validatedUrl, req);
		attachResponseHandlers(http, req);

		final requiresRequestBody = (req.method == "POST" || req.method == "PUT" || req.method == "PATCH");
		http.request(requiresRequestBody);
	}

	private static function buildHttpRequest(validatedUrl:String, req:RequestContext):Http
	{
		final fullUrl = appendQueryParams(validatedUrl, req.queryParams);
		final http = new Http(fullUrl);
		http.cnxTimeout = DEFAULT_TIMEOUT_SECONDS;

		applyHeaders(http, req.headers);
		applyNonStandardMethod(http, req.method);

		if (req.includesRequestBody || req.method != "GET")
			applyRequestBody(http, req.data, req.method, req.contentType);

		return http;
	}

	/**
	 * Applies the HTTP method override for targets that do not natively support
	 * verbs beyond GET and POST.
	 *
	 * On JS, `customRequest` is available and used directly.
	 * On other targets, the de-facto `X-HTTP-Method-Override` header tunnel is used
	 * because haxe.Http only exposes GET/POST at the socket level.
	 */
	private static function applyNonStandardMethod(http:Http, method:String):Void
	{
		if (method == "GET" || method == "POST")
			return;

		#if js
		http.customRequest(method != "POST", method);
		#else
		http.setHeader("X-HTTP-Method-Override", method);
		#end
	}

	private static function applyRequestBody(http:Http, data:Dynamic, method:String, contentType:String):Void
	{
		http.setHeader("Content-Type", contentType);

		if (data == null)
			return;

		final body = serializeBody(data, contentType);
		http.setPostData(body);
		logTrace('Sending $method request');
	}

	private static function serializeBody(data:Dynamic, contentType:String):String
	{
		if (contentType == "application/json")
			return Json.stringify(data);

		if (Std.isOfType(data, String))
			return cast(data, String);

		return Std.string(data);
	}

	private static function attachResponseHandlers(http:Http, req:RequestContext):Void
	{
		var statusCode = 0;

		http.onStatus = status ->
		{
			statusCode = status;
		};

		http.onData = response -> handleDataResponse(statusCode, response, http, req);

		http.onError = error -> handleTransportError(error, req);
	}

	private static function handleDataResponse(statusCode:Int, response:String, http:Http, req:RequestContext):Void
	{
		if (statusCode >= HTTP_CLIENT_ERROR_MIN)
		{
			handleRetryableError('HTTP $statusCode', req);
			return;
		}

		if (statusCode >= HTTP_REDIRECT_MIN)
		{
			handleRedirect(http, req);
			return;
		}

		// statusCode >= HTTP_SUCCESS_MIN — happy path
		logTrace('${req.method} $statusCode - success');
		safeCallback(req.callback, true, response);
	}

	private static function handleRedirect(http:Http, req:RequestContext):Void
	{
		final location = http.responseHeaders.get("Location");
		if (location == null)
		{
			safeCallback(req.callback, false, "Redirect with no Location header");
			return;
		}

		logTrace('Redirecting to $location');

		// POST → GET is standard behaviour after 301/302 (RFC 7231 §6.4).
		// Re-issue as GET so the redirect target receives a safe request.
		dispatchRequest({
			url: location,
			method: "GET",
			data: null,
			includesRequestBody: false,
			headers: req.headers,
			queryParams: null,
			contentType: req.contentType,
			retries: req.retries + 1,
			callback: req.callback
		});
	}

	private static function handleTransportError(error:String, req:RequestContext):Void
	{
		handleRetryableError(error, req);
	}

	private static function handleRetryableError(error:String, req:RequestContext):Void
	{
		final errorType = categorizeError(error);
		logError(errorType, req.url, req.retries);

		if (!isRetryableError(errorType))
		{
			safeCallback(req.callback, false, 'http error ($errorType): $error');
			return;
		}

		logTrace('Retrying... attempt ${req.retries + 1}');
		dispatchRequest({
			url: req.url,
			method: req.method,
			data: req.data,
			includesRequestBody: req.includesRequestBody,
			headers: req.headers,
			queryParams: req.queryParams,
			contentType: req.contentType,
			retries: req.retries + 1,
			callback: req.callback
		});
	}

	private static function validateUrl(url:String):Null<String>
	{
		if (url == null || url.trim() == "")
			return null;

		final parsed = new HttpUrl(url);
		return parsed.valid ? parsed.toString() : null;
	}

	private static function appendQueryParams(baseUrl:String, queryParams:StringMap<String>):String
	{
		if (queryParams == null)
			return baseUrl;

		final pairs = [
			for (key in queryParams.keys())
			{
				final value = queryParams.get(key);
				if (value != null) '$key=${StringTools.urlEncode(value)}';
			}
		];

		return pairs.length > 0 ? baseUrl + "?" + pairs.join("&") : baseUrl;
	}

	private static function applyHeaders(http:Http, headers:StringMap<String>):Void
	{
		if (headers == null)
			return;

		for (key in headers.keys())
			http.setHeader(key, headers.get(key));
	}

	private static function categorizeError(error:String):String
	{
		return switch error
		{
			case e if (e.indexOf("Timeout") != -1): "Timeout Error";
			case e if (e.indexOf("Connection refused") != -1): "Connection Refused";
			case e if (e.indexOf("Invalid URL") != -1): "Invalid URL";
			case e if (e.indexOf("Failed to connect") != -1): "Failed to Connect";
			case e if (e.indexOf("Bad Request") != -1): "Bad Request";
			case e if (e.indexOf("Unauthorized") != -1): "Unauthorized";
			case e if (e.indexOf("Forbidden") != -1): "Forbidden";
			case e if (e.indexOf("Not Found") != -1): "Not Found";
			case e if (e.indexOf("Internal Server Error") != -1): "Internal Server Error";
			case e if (e.indexOf("Service Unavailable") != -1): "Service Unavailable";
			case e if (e.indexOf("Network is unreachable") != -1): "Network Unreachable";
			case e if (e.indexOf("Host is down") != -1): "Host Down";
			case e if (e.indexOf("SSL") != -1): "SSL Error";
			case e if (e.indexOf("Too Many Requests") != -1): "Too Many Requests";
			case e if (e.indexOf("Request Entity Too Large") != -1): "Request Entity Too Large";
			case e if (e.indexOf("Unsupported Media Type") != -1): "Unsupported Media Type";
			case e if (e.indexOf("Not Implemented") != -1): "Not Implemented";
			case e if (e.indexOf("Gateway Timeout") != -1): "Gateway Timeout";
			case e if (e.indexOf("HTTP") != -1): "HTTP Error";
			case e if (e.indexOf("General") != -1): "General Error";
			case _: "Unknown Error";
		}
	}

	private static function isRetryableError(errorType:String):Bool
	{
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

	private static function safeCallback(callback:(Bool, Dynamic) -> Void, success:Bool, result:Dynamic):Void
	{
		if (callback == null)
			return;

		try
		{
			callback(success, result);
		}
		catch (e:Dynamic)
		{
			logTrace("Callback execution failed: " + e);
		}
	}

	private static function logError(error:String, url:String, retries:Int = 0):Void
	{
		CoolLog.error('Error: $error | URL: $url | Retry: $retries');
	}

	private static inline function logTrace(msg:String):Void
	{
		CoolLog.info(msg);
	}
}

private typedef RequestContext =
{
	var url:String;
	var method:String;
	var data:Dynamic;
	var includesRequestBody:Bool;
	var headers:Null<StringMap<String>>;
	var queryParams:Null<StringMap<String>>;
	var contentType:String;
	var retries:Int;
	var callback:(Bool, Dynamic) -> Void;
}

// HttpUrl — validates and parses a URL string
private class HttpUrl
{
	private static final URL_REGEX = ~/^(https?):\/\/([a-zA-Z0-9.-]+)(:[0-9]+)?(\/[^?#]*)?(\?[^#]*)?(#.*)?$/;

	public final url:String;
	public final valid:Bool;
	public final secure:Bool;
	public final host:String;
	public final port:Int;
	public final path:String;

	public function new(url:String)
	{
		this.url = url;
		this.valid = URL_REGEX.match(url);

		if (!this.valid)
		{
			secure = false;
			host = "";
			port = 80;
			path = "/";
			return;
		}

		secure = URL_REGEX.matched(1) == "https";
		host = URL_REGEX.matched(2);
		port = parsePort(URL_REGEX.matched(3));
		path = URL_REGEX.matched(4) ?? "/";
	}

	private function parsePort(portStr:String):Int
	{
		if (portStr != null)
			return Std.parseInt(portStr.substr(1));

		return secure ? 443 : 80;
	}

	public function toString():String
		return url;
}
