# Coconut Data Synchronization

This library allows observing the changes of a coconut model and applying such changes to another model instance.

The ultimate goal is to sync a coconut model to a remote end.

Example:

```haxe
class MyModel implements Model {
	@:editable var int:Int = @byDefault 1;
	@:editable var sub:SubModel = @byDefault new SubModel();
}

class SubModel implements Model {
	@:editable var float:Float = @byDefault 1.1;
}

class Main {
	static function main() {
		Observer.observe()
	}
}

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