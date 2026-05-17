package funkin.ds;

import haxe.ds.StringMap;

typedef RichVar = {
    name:String,
    variables:Dynamic
}

interface IRichTextFormater {
    public function format(text:String):String;
    public function onFormat(text:String, args:Array<RichVar>):String;
}

/*
    Supported syntax inside [...]:

      [tagName]                           – boolean / no-value tag
      [tagName="value"]                   – tag with a primary value
      [tagName="value" attr="a=b" bold]   – tag + extra attributes
      [/tagName]                          – close last matching tag
      [/]                                 – close all tags

    Rules
    -----
    • Attributes are separated by ONE OR MORE spaces.
      No space between attributes is a parse error (traced + tag skipped).
    • Attribute values may be quoted ("…") to include spaces, = signs, etc.
    • Unquoted values stop at the next space.
    • Boolean attributes (no =) are stored as `true`.
*/
class RichTextFormater implements IRichTextFormater {
    var cArguments:Array<RichVar>;
    var onBString:Bool;   // inside a quoted value while scanning the raw text
    var onBBlock:Bool;    // inside [ … ]

    public function new() {
        cArguments = [];
        onBBlock   = false;
        onBString  = false;
    }

    public function format(text:String):String {
        var result      = new StringBuf();
        var currentText = new StringBuf();
        var currentTag  = new StringBuf();

        var i = 0;
        while (i < text.length) {
            var c = text.charAt(i);

            // quote toggle – prevents ] from closing a block mid-value
            if (c == '"') {
                onBString = !onBString;
                if (onBBlock) currentTag.add(c) else currentText.add(c);
                i++; continue;
            }

            // inside a quoted string: accumulate verbatim
            if (onBString) {
                if (onBBlock) currentTag.add(c) else currentText.add(c);
                i++; continue;
            }

            if (c == '[') {
                if (currentText.length > 0) {
                    result.add(onFormat(currentText.toString(), cArguments.copy()));
                    currentText = new StringBuf();
                }
                onBBlock   = true;
                currentTag = new StringBuf();
                i++; continue;
            }

            if (c == ']') {
                onBBlock = false;
                var tagContent = currentTag.toString();
                currentTag = new StringBuf();
                parseTag(tagContent);
                i++; continue;
            }

            if (onBBlock) currentTag.add(c) else currentText.add(c);
            i++;
        }

        if (currentText.length > 0)
            result.add(onFormat(currentText.toString(), cArguments.copy()));

        return result.toString();
    }

    public function onFormat(text:String, args:Array<RichVar>):String {
        return text;
    }

    function parseTag(tagContent:String):Void {
        if (tagContent.length == 0) return;

        if (tagContent.charAt(0) == '/') {
            var tagName = tagContent.substr(1);
            if (tagName.length == 0) {
                cArguments = [];                        // [/]  → clear all
            } else {
                var j = cArguments.length - 1;          // [/tag] → pop last match
                while (j >= 0) {
                    if (cArguments[j].name == tagName) { cArguments.splice(j, 1); break; }
                    j--;
                }
            }
            return;
        }

        var tokens = tokenize(tagContent);
        if (tokens == null) return;   // tokenizer signalled an error

        var first     = splitAttr(tokens[0]);
        var tagName   = first.key;
        var variables:Dynamic = {};

        // primary value lives under "value"; every other attr uses its own key
        if (first.value != null)
            Reflect.setField(variables, 'value', first.value);

        for (k in 1...tokens.length) {
            var attr = splitAttr(tokens[k]);
            Reflect.setField(variables, attr.key, attr.value != null ? attr.value : true);
        }

        cArguments.push({ name: tagName, variables: variables });
    }

    /*  Tokenize a raw tag body into whitespace-separated tokens.
        Spaces inside "…" are treated as part of the value.
        Returns null (+ trace) on malformed input.                            */
    function tokenize(s:String):Null<Array<String>> {
        var tokens    = new Array<String>();
        var current   = new StringBuf();
        var inQuote   = false;
        var lastWasSep = true;  // used to detect missing-space errors

        var i = 0;
        while (i < s.length) {
            var c = s.charAt(i);

            if (c == '"') {
                // closing quote immediately followed by a non-space, non-end char
                // means the author forgot a space  →  error
                if (inQuote) {
                    inQuote = false;
                    current.add(c);
                    // peek ahead
                    if (i + 1 < s.length && s.charAt(i + 1) != ' ') {
                        trace('RichTextFormater: missing space after closing quote in tag: [' + s + ']');
                        return null;
                    }
                } else {
                    // opening quote that doesn't start right after a separator or =
                    // means the author forgot a space before this attribute  →  error
                    if (!lastWasSep && current.length > 0) {
                        var prev = current.toString();
                        if (prev.charAt(prev.length - 1) != '=') {
                            trace('RichTextFormater: missing space before quoted value in tag: [' + s + ']');
                            return null;
                        }
                    }
                    inQuote = true;
                    current.add(c);
                }
                lastWasSep = false;

            } else if (c == ' ' && !inQuote) {
                if (current.length > 0) {
                    tokens.push(current.toString());
                    current = new StringBuf();
                }
                lastWasSep = true;   // allow multiple spaces between tokens

            } else {
                // non-quote, non-space char right after a closing quote  →  error
                // (already caught by the peek-ahead above, but keep as safety net)
                current.add(c);
                lastWasSep = false;
            }

            i++;
        }

        if (inQuote) {
            trace('RichTextFormater: unterminated quote in tag: [' + s + ']');
            return null;
        }

        if (current.length > 0) tokens.push(current.toString());
        return tokens;
    }

    /*  Split one token on its first '='.
        Strips surrounding quotes from the value if present.                  */
    function splitAttr(token:String):{ key:String, value:Null<String> } {
        var eq = token.indexOf('=');
        if (eq == -1) return { key: token, value: null };

        var key = token.substr(0, eq);
        var val = token.substr(eq + 1);

        if (val.length >= 2 && val.charAt(0) == '"' && val.charAt(val.length - 1) == '"')
            val = val.substr(1, val.length - 2);

        return { key: key, value: val };
    }
}