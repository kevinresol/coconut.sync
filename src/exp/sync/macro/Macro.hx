package exp.sync.macro;

import haxe.macro.Type;
import haxe.macro.Expr;

using tink.MacroApi;

class Macro {
	public static function getFields(type:Type, pos:Position):Array<Property> {
		return switch type.reduce() {
			case TAnonymous(_.get() => {fields: fields}):
				[for(field in fields) switch field.type {
					case TAbstract(_.get() => {pack: ['tink', 'state'], name: 'Observable'}, [t]):
						{name: field.name, type: t, pos: field.pos}
					case _:
						field.pos.error('exp.sync: only supports Observable<T>');
				}];
			case v:
				pos.error('exp.sync.Diff only supports anonymous object');
		}
	}
}

typedef Property = {
	name:Name,
	type:Type,
	pos:Position,
}

abstract Name(String) from String to String {
	public inline function toPascalCase():String {
		return this.substr(0, 1).toUpperCase() + this.substr(1);
	}
}