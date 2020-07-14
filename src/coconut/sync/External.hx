package coconut.sync;

#if !macro

@:genericBuild(coconut.sync.External.build())
class External<Model> {}

#else

import coconut.sync.macro.Macro.*;
import haxe.macro.Expr;
import haxe.macro.Context;
import tink.macro.BuildCache;

using tink.MacroApi;

class External {
	static final MODEL = Context.getType('coconut.data.Model');
	
	public static function build() {
		return BuildCache.getType('coconut.sync.External', (ctx:BuildContext) -> {
			final name = ctx.name;
			final pack = ['coconut', 'sync'];
			final modelCt = ctx.type.toComplex();
			final externalCt = TPath({pack: pack, name: name});
			
			final fields = [];
			final init = EObjectDecl(fields).at(ctx.pos);
			
			final def = macro class $name implements coconut.data.Model {
				
				public function new(model:$modelCt) {
					this = $init;
				}
				
				@:transition
				function _cocosync_patch(o) return tink.core.Promise.resolve(o);
			}
			
			for(field in getFields(ctx.type, ctx.pos)) {
				final fname = field.name;
				var fct = field.type.toComplex();
				final isMod = isModel(field.type, field.pos);
				
				if(isMod) fct = macro:coconut.sync.External<$fct>;
				
				def.fields = def.fields.concat((macro class {
					@:observable var $fname:$fct;
				}).fields);
				
				fields.push({
					field: fname,
					expr:
						if(isMod) {
							final ect = field.type.toComplex();
							macro new coconut.sync.External<$ect>(model.$fname);
						} else {
							macro model.$fname;
						},
				});
			}
			
			def.pack = pack;
			def;
		});
	}
}

#end