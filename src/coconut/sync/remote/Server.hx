package coconut.sync.remote;

#if !macro
class Server {
	public static macro function create(createServer, model, serializer);
}

#else

using tink.MacroApi;

class Server {
	
	public static macro function create(createServer, model, serializer) {
		final modelCt = model.typeof().sure().toComplex();
		final serializerCt = macro:why.Serializer<coconut.sync.Change<$modelCt, coconut.sync.Diff<$modelCt>>, String>;
		return macro {
			final model:$modelCt = $model;
			final serializer:$serializerCt = $serializer;
			final signal = coconut.sync.Observer.observe(model);
			
			$createServer()
				.next(server -> {
					server.connected.handle(function(client) {
						client.send(serializer.serialize(Full(model)));
						final binding = signal.handle(function(change) client.send(serializer.serialize(change)));
						client.disconnected.handle(binding);
					});
					{close: server.close}
				});
		}
	}
}

#end