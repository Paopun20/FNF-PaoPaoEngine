package funkin.backend.utils.tools;

@:analyzer(optimize, local_dce, fusion, user_var_fusion)
class NullCheckerTools {
    private static inline function checkNull(check:Dynamic): Bool {
        return check == null;
    }

    public static inline function guyThisIsNull(check:Dynamic):Bool {
        return checkNull(check);
    }

    public static inline function guyThisIsNotNull(check:Dynamic):Bool {
        return !checkNull(check);
    }

    public static inline function iNeedReplaceThisNull<T>(check:T, replace:T):T {
        return checkNull(check) ? replace : check;
    }
}