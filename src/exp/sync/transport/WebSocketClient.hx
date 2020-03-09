package exp.sync.transport;

import tink.websocket.Client.Connector;
import tink.websocket.RawMessage;
import tink.streams.Stream;
import tink.Chunk;

using tink.io.Source;

class WebSocketClient implements Client {
	final connector:Connector;
	
	public function new(connector) {
		this.connector = connector;
	}
	
	public function connect(stream:RealSource):RealSource {
		return connector.connect(stream.chunked().map(Binary).idealize(_ -> Empty.make()))
			.regroup((messages:Array<RawMessage>) -> switch messages {
				case [Text(v)]: Converted(Stream.single((v:Chunk)));
				case [Binary(b)]:  Converted(Stream.single(b));
				case [_]: Converted(Empty.make());
				case _: RegroupResult.Errored(new Error('unreachable'));
			});
	}
}