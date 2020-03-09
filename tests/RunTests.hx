package ;

import tink.unit.*;
import tink.testrunner.*;
import tink.state.*;
import exp.sync.*;

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
		var model:Model = {foo: foo}
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
				
				var expected = foo.value;
				client.model.handle(function(model) {
					asserts.assert(model.foo.value == expected);
					model.foo.bind(null, foo -> {
						asserts.assert(foo == expected);
						if(expected == 3) asserts.done();
					});
				});
				
				function set(v) {
					expected = v;
					foo.set(v);
				}
				
				haxe.Timer.delay(set.bind(3), 200);
				haxe.Timer.delay(set.bind(2), 100);
				set(1);
			case Failure(e):
				asserts.fail(e);
		});
		
		return asserts;
	}
}


typedef Model = {
	final foo:Observable<Int>;
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