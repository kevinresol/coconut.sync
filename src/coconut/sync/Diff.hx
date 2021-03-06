package coconut.sync;

#if !macro
@:genericBuild(coconut.sync.Diff.build())
class Diff<T> {}
#else

import haxe.macro.Context;
import coconut.sync.macro.Macro.*;
import tink.macro.BuildCache;
using tink.MacroApi;

class Diff {
	public static function build() {
		return BuildCache.getType('coconut.sync.Diff', (ctx:BuildContext) -> {
			var name = ctx.name;
			var ct = ctx.type.toComplex();
			
			
			var def = macro class $name {}
			
			for(field in getFields(ctx.type, ctx.pos)) {
				final fname = capitalize(field.name);
				var fct = field.type.toComplex();
				if(isModel(field.type, field.pos)) fct = macro:coconut.sync.DiffKind<$fct>;
				
				def.fields = def.fields.concat((macro class {
					function $fname(v:$fct);
				}).fields);
			}
			
			def.pack = ['coconut', 'sync', 'diff'];
			def.kind = TDEnum;
			def;
		});
	}
}

#end