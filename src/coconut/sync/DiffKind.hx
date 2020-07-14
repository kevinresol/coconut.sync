package coconut.sync;

#if !macro
@:genericBuild(coconut.sync.DiffKind.build())
class DiffKind<T> {}

enum DiffKindBase<F, M> {
	Full(v:F);
	Member(v:M);
}
#else

import haxe.macro.Context;
using tink.MacroApi;

class DiffKind {
	public static function build() {
		return switch Context.getLocalType() {
			case TInst(_, [model]):
				final ct = model.toComplex();
				macro:coconut.sync.DiffKind.DiffKindBase<$ct, coconut.sync.Diff<$ct>>;
			case _:
				throw 'unreachable';
		}
	}
}
#end