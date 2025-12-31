package macro;

#if macro
import haxe.macro.*;
import haxe.macro.Expr;
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;
using Lambda;

class DotEnvMacro
{
	public static macro function build(dotfile:String = '.env'):Array<Field>
	{
		final env = parseEnv(dotfile);
		final fields = Context.getBuildFields();
		for (field in fields)
		{
			if (!field.access.contains(AStatic))
				continue;
			final meta = field.meta.find(m -> m.name == ':env');
			if (meta == null)
				continue;
			if (!isNullString(field.kind))
			{
				Context.fatalError('@:env field "${field.name}" must be of type Null<String>', field.pos);
			}
			final cfg = parseEnvMeta(field.name, meta);
			var value:Null<String> = env.get(cfg.key);
			if (value == null)
			{
				value = cfg.defaultValue;
			}
			if (value == null && cfg.required)
			{
				Context.fatalError('Missing required env value "${cfg.key}"', field.pos);
			}
			field.kind = FVar(getVarType(field.kind), value == null ? macro null : macro $v{value});
		}
		return fields;
	}

	// Meta parsing
	private static function parseEnvMeta(fieldName:String, meta:MetadataEntry):EnvConfig
	{
		var key = fieldName;
		var required = false;
		var def:Null<String> = null;
		for (p in meta.params)
		{
			switch (p.expr)
			{
				case EConst(CString(s, _)):
					key = s;
				case EObjectDecl(fields):
					for (f in fields)
					{
						switch (f.field)
						{
							case 'required':
								required = constBool(f.expr);
							case 'fallback':
								def = constString(f.expr);
							default:
								Context.fatalError('Unknown @:env option "${f.field}"', f.expr.pos);
						}
					}
				default:
					Context.fatalError('Invalid @:env parameters', p.pos);
			}
		}
		return {
			key: key,
			required: required,
			defaultValue: def
		};
	}

	// Const extraction helpers
	private static function constBool(e:Expr):Bool
	{
		return switch (e.expr)
		{
			case EConst(CIdent('true')):
				true;
			case EConst(CIdent('false')):
				false;
			default:
				Context.fatalError('Expected boolean constant', e.pos);
				false;
		}
	}

	private static function constString(e:Expr):String
	{
		return switch (e.expr)
		{
			case EConst(CString(s, _)):
				s;
			default:
				Context.fatalError('Expected string constant', e.pos);
				null;
		}
	}

	// Type helpers
	private static function isNullString(kind:FieldType):Bool
	{
		return switch (kind)
		{
			case FVar(TPath({name: 'Null', params: [TPType(TPath({name: 'String'}))]}), _):
				true;
			default:
				false;
		}
	}

	private static function getVarType(kind:FieldType):ComplexType
	{
		return switch (kind)
		{
			case FVar(t, _):
				t;
			default:
				null;
		}
	}

	// Env file parsing
	private static function parseEnv(path:String):Map<String, String>
	{
		final map:Map<String, String> = [];
		if (!FileSystem.exists(path))
			return map;
		var content = File.getContent(path);
		if (content == null)
			return map;
		content = content.replace("\r\n", "\n");
		for (line in content.split("\n"))
		{
			line = line.trim();
			if (line == "" || line.startsWith("#"))
				continue;
			final eq = line.indexOf("=");
			if (eq <= 0)
				continue;
			var key = stripTargetPrefix(line.substr(0, eq).trim());
			if (shouldExcludeKey(key))
				continue;
			var value = line.substr(eq + 1).trim();
			value = stripQuotes(value);
			map.set(key, value);
		}
		return map;
	}

	private static function stripQuotes(v:String):String
	{
		if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'")))
		{
			return v.substr(1, v.length - 2);
		}
		return v;
	}

	// Target logic
	private static function shouldExcludeKey(key:String):Bool
	{
		final isAndroid = key.startsWith("ANDROID_");
		final isIos = key.startsWith("IOS_");
		final isWeb = key.startsWith("WEB_");
		final isDesktop = key.startsWith("DESKTOP_");
		final isMobile = key.startsWith("MOBILE_") || isAndroid || isIos;
		#if web
		return isMobile || isDesktop;
		#elseif desktop
		return isMobile || isWeb;
		#elseif android
		return isIos || isWeb || isDesktop;
		#elseif ios
		return isAndroid || isWeb || isDesktop;
		#end
		return false;
	}

	private static function stripTargetPrefix(key:String):String
	{
		final i = key.indexOf("_");
		if (i == -1)
			return key;
		final prefix = key.substr(0, i);
		final rest = key.substr(i + 1);
		return switch (prefix)
		{
			#if android
			case "ANDROID", "MOBILE": rest;
			#elseif ios
			case "IOS", "MOBILE": rest;
			#elseif web
			case "WEB": rest;
			#elseif desktop
			case "DESKTOP": rest;
			#end
			default:
				key;
		}
	}
}

// Types

private typedef EnvConfig =
{
	final key:String;
	final required:Bool;
	final defaultValue:Null<String>;
}
