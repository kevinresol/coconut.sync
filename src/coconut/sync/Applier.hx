package coconut.sync;

#if !macro


class Applier {
	public static macro function apply(model, diff);
}

@:genericBuild(coconut.sync.Applier.build())
class DiffApplier<Model> {}

#else

import haxe.macro.Expr;
import haxe.macro.Context;
import tink.macro.BuildCache;
import coconut.sync.macro.Macro.*;

using tink.MacroApi;

class Applier {
	
	public static macro function apply(ext:Expr, diff:Expr) {
		return switch ext.typeof() {
			case Success(type):
				final ct = (macro @:privateAccess $ext._cocosync_model()).typeof().sure().toComplex();
				macro new coconut.sync.Applier.DiffApplier<$ct>().apply($ext, $diff);
			case Failure(e):
				ext.pos.error(e);
		}
	}
	
	public static function build() {
		return BuildCache.getType('coconut.sync.DiffApplier', (ctx:BuildContext) -> {
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
						expr: macro coconut.sync.Applier.apply(model.$fname, v),
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