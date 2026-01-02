package funkin.backend;

using Lambda;

private enum TokenType
{
	TkInvalid;
	TkComment;
	TkKey;
	TkKeygroup;
	TkString;
	TkInteger;
	TkFloat;
	TkBoolean;
	TkDatetime;
	TkAssignment;
	TkComma;
	TkBBegin;
	TkBEnd;
}

private typedef Token =
{
	var type:TokenType;
	var value:String;
	var lineNum:Int;
	var colNum:Int;
}

class TomlParser
{
	var tokens:Array<Token>;
	var root:Dynamic;
	var pos = 0;

	public var currentToken(get, null):Token;

	/** Set up a new TomlParser instance */
	public function new()
	{
	}

	/** Parse a TOML string into a dynamic object.  Throws a String containing an error message if an error is encountered. */
	public function parse(str:String, ?defaultValue:Dynamic):Dynamic
	{
		tokens = tokenize(str);

		// for(token in tokens)
		// trace(token);

		if (defaultValue != null)
		{
			root = defaultValue;
		}
		else
		{
			root = {};
		}
		pos = 0;

		parseObj();

		return root;
	}

	function get_currentToken()
	{
		return tokens[pos];
	}

	function nextToken()
	{
		pos++;
	}

	function parseObj()
	{
		var keygroup = "";

		while (pos < tokens.length)
		{
			switch (currentToken.type)
			{
				case TkKeygroup:
					keygroup = decodeKeygroup(currentToken);
					createKeygroup(keygroup);
					nextToken();
				case TkKey:
					var pair = parsePair();
					setPair(keygroup, pair);
				default:
					InvalidToken(currentToken);
			}
		}
	}

	function parsePair()
	{
		var key = "";
		var value = {};

		if (currentToken.type == TkKey)
		{
			key = decodeKey(currentToken);
			nextToken();

			if (currentToken.type == TkAssignment)
			{
				nextToken();
				value = parseValue();
			}
			else
			{
				InvalidToken(currentToken);
			}
		}
		else
		{
			InvalidToken(currentToken);
		}

		return {key: key, value: value};
	}

	function parseValue():Dynamic
	{
		var value:Dynamic = {};

		switch (currentToken.type)
		{
			case TkString:
				value = decodeString(currentToken);
				nextToken();
			case TkDatetime:
				value = decodeDatetime(currentToken);
				nextToken();
			case TkFloat:
				value = decodeFloat(currentToken);
				nextToken();
			case TkInteger:
				value = decodeInteger(currentToken);
				nextToken();
			case TkBoolean:
				value = decodeBoolean(currentToken);
				nextToken();
			case TkBBegin:
				value = parseArray();
			default:
				InvalidToken(currentToken);
		};

		return value;
	}

	function parseArray()
	{
		var array = [];

		if (currentToken.type == TokenType.TkBBegin)
		{
			nextToken();
			while (true)
			{
				if (currentToken.type != TkBEnd)
				{
					array.push(parseValue());
				}
				else
				{
					nextToken();
					break;
				}

				switch (currentToken.type)
				{
					case TkComma:
						nextToken();
					case TkBEnd:
						nextToken();
						break;
					default:
						InvalidToken(currentToken);
				}
			}
		}

		return array;
	}

	function createKeygroup(keygroup:String)
	{
		var keys = keygroup.split(".");
		var obj = root;

		for (key in keys)
		{
			var next = Reflect.field(obj, key);
			if (next == null)
			{
				Reflect.setField(obj, key, {});
				next = Reflect.field(obj, key);
			}
			obj = next;
		}
	}

	function setPair(keygroup:String, pair:{key:String, value:Dynamic})
	{
		var keys = keygroup.split(".");
		var obj = root;

		for (key in keys)
		{
			// A Haxe glitch: empty string will be parsed to [""]
			if (key != "")
			{
				obj = Reflect.field(obj, key);
			}
		}

		Reflect.setField(obj, pair.key, pair.value);
	}

	function decode<T>(token:Token, expectedType:TokenType, decoder:String->T):T
	{
		var type = token.type;
		var value = token.value;

		if (type == expectedType)
			return decoder(value);
		else
			throw('Can\'t parse $type as $expectedType');
	}

	function decodeKeygroup(token:Token):String
	{
		return decode(token, TokenType.TkKeygroup, function(v)
		{
			return v.substring(1, v.length - 1);
		});
	}

	function decodeString(token:Token):String
	{
		return decode(token, TokenType.TkString, function(v)
		{
			try
			{
				return unescape(v);
			}
			catch (msg:String)
			{
				InvalidToken(token);
				return "";
			};
		});
	}

	function decodeDatetime(token:Token):Date
	{
		return decode(token, TokenType.TkDatetime, function(v)
		{
			var dateStr = ~/(T|Z)/.replace(v, "");
			return Date.fromString(dateStr);
		});
	}

	function decodeFloat(token:Token):Float
	{
		return decode(token, TokenType.TkFloat, function(v)
		{
			return Std.parseFloat(v);
		});
	}

	function decodeInteger(token:Token):Int
	{
		return decode(token, TokenType.TkInteger, function(v)
		{
			return Std.parseInt(v);
		});
	}

	function decodeBoolean(token:Token):Bool
	{
		return decode(token, TokenType.TkBoolean, function(v)
		{
			return v == "true";
		});
	}

	function decodeKey(token:Token):String
	{
		return decode(token, TokenType.TkKey, function(v)
		{
			return v;
		});
	}

	function unescape(str:UnicodeString)
	{
		var pos = 0;
		var buf = new StringBuf();

		var len = str.length;
		while (pos < len)
		{
			var c = str.charCodeAt(pos);

			// strip first and last quotation marks
			if ((pos == 0 || pos == len - 1) && c == "\"".code)
			{
				pos++;
				continue;
			}

			pos++;

			if (c == "\\".code)
			{
				c = str.charCodeAt(pos);
				pos++;

				switch (c)
				{
					case "r".code:
						buf.addChar("\r".code);
					case "n".code:
						buf.addChar("\n".code);
					case "t".code:
						buf.addChar("\t".code);
					case "b".code:
						buf.addChar(8);
					case "f".code:
						buf.addChar(12);
					case "/".code, "\\".code, "\"".code:
						buf.addChar(c);
					case "u".code:
						var uc = Std.parseInt("0x" + str.substr(pos, 4));
						buf.addChar(uc);
						pos += 4;
					default:
						throw("Invalid Escape");
				}
			}
			else
			{
				buf.addChar(c);
			}
		}

		return buf.toString();
	}

	function tokenize(src:String):Array<Token>
	{
		var tokens:Array<Token> = [];
		var lines = src.split("\n");

		for (lineNum in 0...lines.length)
		{
			var line = lines[lineNum];
			var col = 0;

			while (col < line.length)
			{
				// skip whitespace
				while (col < line.length && StringTools.isSpace(line, col))
					col++;
				if (col >= line.length)
					break;

				var ch = line.charAt(col);

				// comment
				if (ch == "#")
					break;

				// keygroup [a.b.c]
				if (ch == "[")
				{
					var end = line.indexOf("]", col);
					if (end == -1)
						InvalidCharacter("[", lineNum, col);
					tokens.push({
						type: TkKeygroup,
						value: line.substring(col, end + 1),
						lineNum: lineNum,
						colNum: col
					});
					col = end + 1;
					continue;
				}

				// assignment
				if (ch == "=")
				{
					tokens.push({
						type: TkAssignment,
						value: "=",
						lineNum: lineNum,
						colNum: col
					});
					col++;
					continue;
				}

				// comma
				if (ch == ",")
				{
					tokens.push({
						type: TkComma,
						value: ",",
						lineNum: lineNum,
						colNum: col
					});
					col++;
					continue;
				}

				// array begin / end
				if (ch == "[")
				{
					tokens.push({
						type: TkBBegin,
						value: "[",
						lineNum: lineNum,
						colNum: col
					});
					col++;
					continue;
				}
				if (ch == "]")
				{
					tokens.push({
						type: TkBEnd,
						value: "]",
						lineNum: lineNum,
						colNum: col
					});
					col++;
					continue;
				}

				// string
				if (ch == "\"")
				{
					var start = col;
					col++;
					var escaped = false;
					while (col < line.length)
					{
						var c = line.charAt(col);
						if (!escaped && c == "\"")
							break;
						escaped = (!escaped && c == "\\");
						col++;
					}
					if (col >= line.length)
						InvalidCharacter("\"", lineNum, start);
					col++; // include closing quote
					tokens.push({
						type: TkString,
						value: line.substring(start, col),
						lineNum: lineNum,
						colNum: start
					});
					continue;
				}

				// bare token (key / number / bool / datetime)
				var start = col;
				while (col < line.length && !StringTools.isSpace(line, col) && ",=[]#".indexOf(line.charAt(col)) == -1)
				{
					col++;
				}
				var word = line.substring(start, col);

				// classify
				var ttype = if (~/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/.match(word)) TkDatetime else if (~/^-?\d+\.\d+$/.match(word)) TkFloat else
					if (~/^-?\d+$/.match(word)) TkInteger else if (word == "true"
					|| word == "false") TkBoolean else TkKey;

				tokens.push({
					type: ttype,
					value: word,
					lineNum: lineNum,
					colNum: start
				});
			}
		}

		return tokens;
	}

	function InvalidCharacter(char:String, lineNum:Int, colNum:Int)
	{
		throw('Line $lineNum Character ${colNum + 1}: ' + 'Invalid Character \'$char\', ' + 'Character Code ${char.charCodeAt(0)}');
	}

	function InvalidToken(token:Token)
	{
		throw('Line ${token.lineNum + 1} Character ${token.colNum + 1}: ' + 'Invalid Token \'${token.value}\'(${token.type})');
	}

	/** Static shortcut method to parse toml String into Dynamic object. */
	public static function parseString(toml:String, defaultValue:Dynamic)
	{
		return (new TomlParser()).parse(toml, defaultValue);
	}

	/** Static shortcut method to read toml file and parse into Dynamic object */
	public static function parseFile(filename:String, ?defaultValue:Dynamic)
	{
		return parseString(sys.io.File.getContent(filename), defaultValue);
	}
}
