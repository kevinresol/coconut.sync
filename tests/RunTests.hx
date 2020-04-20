package ;

import tink.unit.*;
import tink.testrunner.*;
import tink.state.*;
import exp.sync.*;

using tink.CoreApi;

@:asserts
class RunTests {

	static function main() {
		Runner.run(TestBatch.make([
			new RunTests(),
		])).handle(Runner.exit);
	}

	function new() {}
	
	public function test() {
		
		var foo = new State(0);
		var bar = new State(0);
		var model:Model = {foo: foo, bar: bar}
		// var binder = exp.sync.transport.LocalServer.bind;
		var binder = exp.sync.transport.WebSocketServer.bind.bind(new tink.websocket.servers.NodeWsServer({port: 1324}));
		var serializer = new why.serialize.StringToChunk(new why.serialize.JsonSerializer<Diff<Model>>());
		Server.create(binder, serializer, model).handle(function(o) switch o {
			case Success(server):
				// var server:exp.sync.transport.LocalServer = cast @:privateAccess server.transport;
				// var transport = new exp.sync.transport.LocalClient(server);
				
				untyped global.WebSocket = js.Lib.require('ws');
				var transport = new exp.sync.transport.WebSocketClient(new tink.websocket.clients.JsConnector('ws://localhost:1324'));
				
				var client = new Client<Model>(transport, serializer);
				
				var expected_foo = foo.value;
				var expected_bar = bar.value;
				
				var fooDone = Future.trigger();
				var barDone = Future.trigger();
				
				client.model.handle(function(model) {
					asserts.assert(model.foo.value == expected_foo);
					asserts.assert(model.bar.value == expected_bar);
					
					model.foo.bind(null, foo -> {
						asserts.assert(foo == expected_foo);
						if(expected_foo == 3) fooDone.trigger(Noise);
					});
					model.bar.bind(null, bar -> {
						asserts.assert(bar == expected_bar);
						if(expected_bar == 3) barDone.trigger(Noise);
					});
				});
				
				function set_foo(v) {
					expected_foo = v;
					foo.set(v);
				}
				
				function set_bar(v) {
					expected_bar = v;
					bar.set(v);
				}
				
				haxe.Timer.delay(set_foo.bind(3), 200);
				haxe.Timer.delay(set_foo.bind(2), 100);
				set_foo(1);
				
				haxe.Timer.delay(set_bar.bind(3), 250);
				haxe.Timer.delay(set_bar.bind(2), 50);
				set_bar(1);
				
				Promise.lift(fooDone.asFuture() && barDone.asFuture()).handle(asserts.handle);
			case Failure(e):
				asserts.fail(e);
		});
		
		return asserts;
	}
}


typedef Model = {
	final foo:Observable<Int>;
	final bar:Observable<Int>;
}


/*


class Sync {
	static function server() {
		var model:Model;
		var serializer;
		var transport = new WebSocketServerTransport(1324);
		var server = new SyncServer<Model>(WebSocketServerTransport.bind(1324), serializer, model);
		
	}
	
	static function client() {
		var serializer;
		var transport = new WebSocketClientTransport('localhost', 1324);
		var client = new SyncClient<Model>(transport, serializer);
		client.model.handle(function(model) {
			$type(model.data); // Model
			$type(model.data.foo); // Observable<Int>
			$type(model.control.error); // Signal<Error>
			$type(model.control.disconnected); // Future<Noise>
			$type(model.control.lastUpdate); // Observable<Date>
		});
	}
}
*/