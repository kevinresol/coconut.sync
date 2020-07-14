package coconut.sync.remote;

#if !macro
class Client {
	public static macro function create(createClient, serializer);
}

#else

using tink.MacroApi;

class Client {
	
	public static macro function create(createClient, serializer) {
		return switch serializer {
			case macro ($serializer:$modelCt):
				final extCt = macro:coconut.sync.External<$modelCt>;
				final diffKindCt = macro:coconut.sync.DiffKind<$modelCt>;
				final serializerCt = macro:why.Serializer<$diffKindCt, String>;
				return macro {
					var ext:$extCt = null;
					@:pos(serializer.pos) final serializer:$serializerCt = $serializer;
					
					$createClient()
						.next(client -> {
							model:
								client.data
									.map(chunk -> tink.Json.parse((chunk:$diffKindCt)))
									.pickNext(o -> switch o {
										case Success(Full(v)): Some(ext = new coconut.sync.External<$modelCt>(v));
										case _: None;
									}),
							binding:
								client.data.handle(function(chunk) {
									switch tink.Json.parse((chunk:$diffKindCt)) {
										case Success(Member(diff)):
											coconut.sync.Applier.apply(ext, diff);
										case Success(Full(_)):
											// already handled
										case Failure(e):
											// TODO: propagate error
									}
								}),
						});
				}
			case {pos: pos}:
				pos.error('Expected ECheckType syntax');
		}		
	}
}

#end