# Coconut Data Synchronization

This library enables real-time & uni-directional synchronization of a coconut model over the network.

## Components

**Observer**

```haxe
class Observer {
	// Observe a model and emit a stream of "Diff" objects
	public static function observe<M>(model:M):Signal<Diff<M>>;
}
```

**Applier**

```haxe
class Applier {
	// Apply "Diff" objects to an "External" model to update its values
	public static function apply<M>(model:External<M>, diff:Diff<M>):Void;
}
```

**External**

`External<M>` implements `coconut.data.Model` and is basically the same as `M`, except all its fields becomes `@:external`

**Diff**

`Diff<M>` is an `enum` to describe the changes of a particular field of a model


## Example:

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
						// except its type is `External<MyModel>` where all fields become `@:external` and are readonly
					});
				case Failure(e):
					trace(e);
			});
	}
}
```

TODO:

- Batch changes