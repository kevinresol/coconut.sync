package coconut.sync;

#if !macro

class Observer {
	public static macro function observe(model, ?direct);
}

@:genericBuild(coconut.sync.Observer.build())
class ModelObserver<Model> {}

#else

import coconut.sync.macro.Macro.*;
import haxe.macro.Expr;
import haxe.macro.Context;
import tink.macro.BuildCache;

using tink.MacroApi;

class Observer {
	static final MODEL = Context.getType('coconut.data.Model');
	
	public static macro function observe(model:Expr, ?direct:Expr) {
		return switch model.typeof() {
			case Success(type):
				final ct = type.toComplex();
				macro new coconut.sync.Observer.ModelObserver<$ct>($model, $direct);
			case Failure(e):
				model.pos.error(e);
		}
	}
	
	public static function build() {
		return BuildCache.getType('coconut.sync.ModelObserver', (ctx:BuildContext) -> {
			final name = ctx.name;
			final modelCt = ctx.type.toComplex();
			final changeCt = macro:coconut.sync.Change<$modelCt, coconut.sync.Diff<$modelCt>>;
			
			var body = [];
			final def = macro class $name {
				public function new(model:$modelCt, direct = false) {
					this = new tink.core.Signal((trigger:$changeCt->Void) -> {
						var binding:tink.core.Callback.CallbackLink = null;
						$b{body};
						binding;
					});
				}
			}
			
			for(field in getFields(ctx.type, ctx.pos)) {
				final fname = field.name;
				final ename = capitalize(fname);
				final fct = field.type.toComplex();
				if(!isModel(field.type, field.pos)) {
					body.push(macro {
						var first = true;
						binding &= model.observables.$fname.bind({direct: direct}, v -> {
							if(first) first = false;
							else trigger(Member($i{ename}(v)));
						});
					});
				} else {
					body.push(macro binding &= {
						var binding:tink.core.Callback.CallbackLink = null;
						var first = true;
						[
							model.observables.$fname.bind({direct: direct}, model -> {
								binding.cancel();
								if(first) first = false;
								else trigger(Member($i{ename}(Full(model))));
								binding = coconut.sync.Observer.observe(model, direct).handle(v -> {
									trigger(Member($i{ename}(v)));
								});
							}),
							(function() binding.cancel():tink.core.Callback.CallbackLink),
						];
					});
				}
			}
			
			final underlying = macro:tink.core.Signal<$changeCt>;
			def.kind = TDAbstract(underlying, [underlying], [underlying]);
			def.meta = [{name: ':forward', pos: ctx.pos}];
			def.pack = ['coconut', 'sync'];
			def;
		});
	}
}

#end