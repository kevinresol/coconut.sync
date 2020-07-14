package coconut.sync;

#if !macro

@:genericBuild(coconut.sync.Applier.build())
class Applier<Model> {}

#else

import haxe.macro.Expr;
import haxe.macro.Context;
import tink.macro.BuildCache;
import coconut.sync.macro.Macro.*;

using tink.MacroApi;

class Applier {
	public static function build() {
		return BuildCache.getType('coconut.sync.Applier', (ctx:BuildContext) -> {
			final name = ctx.name;
			final modelCt = ctx.type.toComplex();
			final extCt = macro:coconut.sync.External<$modelCt>;
			final diffCt = macro:coconut.sync.Diff<$modelCt>;
			
			final cases = [];
			final sw = ESwitch(macro diff, cases, null).at(ctx.pos);
			
			for(field in getFields(ctx.type, ctx.pos)) {
				final fname = field.name;
				final fct = field.type.toComplex();
				if(isModel(field.type, field.pos)) {
					cases.push({
						values: [macro $i{fname}(Full(v))],
						expr: macro model._cocosync_patch({$fname: new coconut.sync.External<$fct>(v)})
					});
					cases.push({
						values: [macro $i{fname}(Member(v))],
						expr: macro new coconut.sync.Applier<$fct>().apply(model.$fname, v),
					});
				} else {
					cases.push({
						values: [macro $i{fname}(v)],
						expr: macro model._cocosync_patch({$fname: v}),
					});
				}
			}
			
			final def = macro class $name {
				public function new() {}
				public function apply(model:$extCt, diff:$diffCt) $sw;
			}
			def.pack = ['coconut', 'sync'];
			def;
		});
	}
}

#end