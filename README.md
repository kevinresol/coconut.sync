# [Experimental] Remote State Synchronization

Based on `Observable` from [tink_state](https://github.com/haxetink/tink_state).

Given a bucket of observable values on a server, this library supports synchronizing the changes to a remote observer (e.g. over the network)

Example:

```haxe
typedef Model = {
	foo:Observable<Int>,
}

class Server {
	static function main() {
		var model:Model = ...;
		var binder = WebSocketServer.bind.bind(new NodeWsServer({port: 1324}));
		var serializer = new StringToChunk(new JsonSerializer<Diff<Model>>());
		Server.create(binder, serializer, model).handle(function(o) switch o {
			case Success(server):
				// sync server running:
				// from now on, whenever `model.foo` changes, the updates will be broadcast to all connected clients 
			case Failure(e):
				// errored in creating the sync server
		});
	}
}

class Client {
	static function main() {
		var transport = new WebSocketClient(new JsConnector('ws://localhost:1324'));
		var client = new Client<Model>(transport, serializer);
		
		client.model.handle(function(model:Model) {
			// `client.model` will resolve after connecting to server and obtaining the initial model values
			
			// server changes can be observed from now on
			model.foo.bind(null, foo -> trace(foo));
		});
	}
}
```

TODO:

- Batch changes
- Support more data types (e.g. nested object)