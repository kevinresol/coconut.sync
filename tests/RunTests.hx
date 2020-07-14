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
		var model = new MyModel();
		var signal = Observer.observe(model, true);
		
		var current = null;
		signal.handle(function(v) current = v);
		asserts.assert(current == null);
		
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
		
		final signal:SignalTrigger<DiffKind<MyModel>> = Signal.trigger();
		var ext:External<MyModel> = null;
		
		signal.listen(function(change) {
			switch change {
				case Full(model):
					ext = new External<MyModel>(model);
				case Member(diff):
					Applier.apply(ext, diff);
			}
		});
		
		signal.trigger(Full(new MyModel()));
		asserts.assert(ext != null);
		asserts.assert(ext.i == 0);
		asserts.assert(ext.n == null);
		
		signal.trigger(Member(i(1)));
		asserts.assert(ext.i == 1);
		
		var sub = ext.s;
		signal.trigger(Member(s(Full(new SubModel()))));
		asserts.assert(ext.s != sub);
		asserts.assert(ext.s.i1 == 0);
		
		signal.trigger(Member(s(Member(i1(2)))));
		asserts.assert(ext.s.i1 == 2);
		
		signal.trigger(Member(s(Full(null))));
		asserts.assert(ext.s == null);
		
		return asserts.done();
	}
	
	public function server() {
		var model = new MyModel();
		var serializer = new why.serialize.JsonSerializer<DiffKind<MyModel>>();
		coconut.sync.remote.Server.create(why.duplex.websocket.WebSocketServer.bind.bind({port: 8080}), model, serializer)
			.handle(function(o) switch o {
				case Success(server):
					asserts.done();
				case Failure(e):
					asserts.fail(e);
			});
		return asserts;
	}
	
	public function client() {
		// FIXME: currently this test relies on the fact that the server opened in the previous test is not closed
		var serializer = new why.serialize.JsonSerializer<DiffKind<MyModel>>();
		coconut.sync.remote.Client.create(why.duplex.websocket.WebSocketClient.connect.bind('ws://localhost:8080'), (serializer:MyModel))
			.handle(function(o) switch o {
				case Success(client):
					client.model.handle(asserts.done);
				case Failure(e):
					asserts.fail(e);
			});
		return asserts;
	}
}

@:jsonStringify((_:coconut.json.Serializer<RunTests.MyModel>))
@:jsonParse((_:coconut.json.Unserializer<RunTests.MyModel>))
class MyModel implements Model {
	@:editable var i:Int = @byDefault 0;
	@:editable var s:SubModel = @byDefault new SubModel();
	@:editable var n:SubModel = @byDefault null;
}


@:jsonStringify((_:coconut.json.Serializer<RunTests.SubModel>))
@:jsonParse((_:coconut.json.Unserializer<RunTests.SubModel>))
class SubModel implements Model {
	@:editable var i1:Int = @byDefault 0;
	@:editable var s1:SubModel2 = @byDefault new SubModel2();
}

@:jsonStringify((_:coconut.json.Serializer<RunTests.SubModel2>))
@:jsonParse((_:coconut.json.Unserializer<RunTests.SubModel2>))
class SubModel2 implements Model {
	@:editable var i2:Int = @byDefault 0;
}