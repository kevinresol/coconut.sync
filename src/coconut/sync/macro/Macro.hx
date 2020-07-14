package coconut.sync.macro;

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;

using tink.CoreApi;
using tink.MacroApi;

class Macro {
	static final MODEL = Context.getType('coconut.data.Model');
	
	public static function getFields(type:Type, pos:Position) {
		final ct = type.toComplex();
		return
			if(!isModel(type, pos))
				pos.error('${type.getID()} should implement coconut.data.Model');
			else 
				switch (macro (null : $ct).observables).typeof().sure() {
					case TAnonymous(_.get() => {fields: fields}):
						fields.filter(f -> f.name != 'isInTransition')
							.map(f -> {
								final ct = f.type.toComplex();
								{
									name: f.name,
									pos: f.pos,
									type: (macro (null:$ct).value).typeof().sure(),
								}
							});
					case _: throw 'unreachable';
				}
	}
	
	public static function isModel(type:Type, pos) {
		return type.isSubTypeOf(MODEL, pos).isSuccess();
	}
	
	public static function capitalize(v:String) {
		return v;
		// return v.charAt(0).toUpperCase() + v.substr(1);
	}
	
}

typedef Property = {
	name:Name,
	type:Type,
	kind:PropertyKind,
	pos:Position,
}

enum PropertyKind {
	Value;
	Sub;
}

abstract Name(String) from String to String {
	public inline function toPascalCase():String {
		return this.substr(0, 1).toUpperCase() + this.substr(1);
	}
}