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

class Server {
	static function main() {
		var model = new MyModel();
		var serializer = new why.serialize.JsonSerializer<DiffKind<MyModel>>();
		coconut.sync.remote.Server.create(why.duplex.websocket.WebSocketServer.bind.bind({port: 8080}), model, serializer)
			.handle(function(o) switch o {
				case Success(server):
					// server is successfully set up
					// it will listen for incoming connections
					// when a client is connected, it will send a full current snapshot of the model to the client
					// then any subsequent changes will also be sent
				case Failure(e):
					trace(e);
			});
	}
}

class Client {
	static function main() {
		var serializer = new why.serialize.JsonSerializer<DiffKind<MyModel>>();
		coconut.sync.remote.Client.create(why.duplex.websocket.WebSocketClient.connect.bind('ws://localhost:8080'), (serializer:MyModel))
			.handle(function(o) switch o {
				case Success(client):
					// client successfully connected to server
					
					client.model.handle(model -> {
						// client successfully received the initial model snapshot
						// from now on `model` can be used just like an ordinary `MyModel`
						// except its type is `External<MyModel>` where all fields become `@:external`
					});
				case Failure(e):
					trace(e);
			});
	}
}
```

TODO:

- Batch changes