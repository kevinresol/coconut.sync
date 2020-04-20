package exp.sync;

#if !macro
@:genericBuild(exp.sync.Diff.build())
class Diff<T> {}

@:genericBuild(exp.sync.Diff.buildInit())
class Init<T> {}

@:genericBuild(exp.sync.Diff.buildPart())
class Part<T> {}
#else

import tink.macro.BuildCache;
using tink.MacroApi;

class Diff {
	public static function build() {
		return BuildCache.getType('exp.sync.Diff', (ctx:BuildContext) -> {
			var name = ctx.name;
			var ct = ctx.type.toComplex();
			
			var def = macro class $name {
				function Full(v:exp.sync.Diff.Init<$ct>);
				function Partial(v:exp.sync.Diff.Part<$ct>);
			}
			
			def.pack = ['exp', 'sync', 'diff'];
			def.kind = TDEnum;
			def;
		});
	}
	public static function buildPart() {
		return BuildCache.getType('exp.sync.Part', (ctx:BuildContext) -> {
			var name = ctx.name;
			var type = ctx.type;
			var ct = ctx.type.toComplex();
			
			var def = macro class $name {}
			
			for(field in exp.sync.macro.Macro.getFields(ctx.type, ctx.pos)) {
				def.fields.push({
					name: field.name.toPascalCase(),
					kind: FFun({
						args: [field.name.toArg(field.type.toComplex())],
						expr: null,
						ret: null,
					}),
					pos: field.pos,
				});
			}
			
			def.pack = ['exp', 'sync', 'diff'];
			def.kind = TDEnum;
			def;
		});
	}
	public static function buildInit() {
		return BuildCache.getType('exp.sync.Init', (ctx:BuildContext) -> {
			var name = ctx.name;
			var type = ctx.type;
			var ct = ctx.type.toComplex();
			
			var def = macro class $name {}
			
			for(field in exp.sync.macro.Macro.getFields(ctx.type, ctx.pos)) {
				def.fields.push({
					name: field.name,
					kind: FVar(field.type.toComplex(), null),
					pos: field.pos,
				});
			}
			
			def.pack = ['exp', 'sync', 'diff'];
			def.kind = TDStructure;
			def;
		});
	}
}

#end