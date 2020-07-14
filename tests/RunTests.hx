package ;

import tink.unit.*;
import tink.testrunner.*;
import coconut.data.*;
import coconut.sync.*;

using tink.CoreApi;

@:timeout(10000)
@:asserts
class RunTests {

	static function main() {
		Runner.run(TestBatch.make([
			new RunTests(),
		])).handle(Runner.exit);
	}

	function new() {}
	
	public function observe() {
		// Callback.defer(() -> {
		var model = new MyModel();
		var observer = new ModelObserver<MyModel>(model, true);
		
		var current = null;
		observer.handle(function(v) current = v);
		
		model.i = 1;
		asserts.assert(current.match(Member(i(1))));
		
		model.s = new SubModel();
		switch current {
			case Member(s(Full(v))): asserts.assert(v == model.s);
			case _: asserts.fail('unexpected');
		}
		
		model.s.i1 = 5;
		asserts.assert(current.match(Member(s(Member(i1(5))))));
		
		model.s.s1 = new SubModel2();
		switch current {
			case Member(s(Member(s1(Full(v))))): asserts.assert(v == model.s.s1);
			case _: asserts.fail('unexpected');
		}
		
		model.s.s1.i2 = 6;
		asserts.assert(current.match(Member(s(Member(s1(Member(i2(6))))))));
		
		
			
		return asserts.done();
	}
	
	public function apply() {
		
		final signal:SignalTrigger<Part<MyModel, Diff<MyModel>>> = Signal.trigger();
		var ext:External<MyModel> = null;
		
		/*
		final c:Container<MyModel> = null;
		
		class Container {
			function handler(part:Part<MyModel, Diff<MyModel>>) {
				switch part {
					
				}
			}
		}
		
		signal.listen(c.handler);
		*/
		
		
		// signal.listen(Applier.make(ext));
		
		signal.listen(function(part) {
			switch part {
				case Full(model):
					ext = new External<MyModel>(model);
				case Member(diff):
					new Applier<MyModel>().apply(ext, diff);
			}
		});
		
		signal.trigger(Full(new MyModel()));
		asserts.assert(ext != null);
		asserts.assert(ext.i == 0);
		
		signal.trigger(Member(i(1)));
		asserts.assert(ext.i == 1);
		
		var sub = ext.s;
		signal.trigger(Member(s(Full(new SubModel()))));
		asserts.assert(ext.s != sub);
		asserts.assert(ext.s.i1 == 0);
		
		signal.trigger(Member(s(Member(i1(2)))));
		asserts.assert(ext.s.i1 == 2);
		
		return asserts.done();
	}
	
	static function update() {
		tink.state.Observable.updateAll();
	}
}

class MyModel implements Model {
	@:editable var i:Int = @byDefault 0;
	@:editable var s:SubModel = @byDefault new SubModel();
}

class SubModel implements Model {
	@:editable var i1:Int = @byDefault 0;
	@:editable var s1:SubModel2 = @byDefault new SubModel2();
}

class SubModel2 implements Model {
	@:editable var i2:Int = @byDefault 0;
}