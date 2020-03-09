package exp.sync.transport;

import tink.websocket.Server as Base;
import tink.streams.Stream.SignalStream;
import tink.streams.Stream.Handled;

using tink.io.Source;

class WebSocketServer implements Server {
	public static function bind(base:Base, handler:Handler):Promise<Server> {
		var server = new WebSocketServer(base, handler);
		return Promise.resolve((server:Server));
	}
	
	final base:Base;
	
	function new(base:Base, handler:Handler) {
		this.base = base;
		base.clientConnected.handle(client -> {
			var signal = Signal.trigger();
			var incoming:RealSource = new SignalStream(signal);
			client.messageReceived.handle(message -> switch message {
				case Text(v): signal.trigger(Data(v));
				case Binary(v): signal.trigger(Data(v));
			});
			client.closed.handle(_ -> signal.trigger(End));
			
			var outgoing = handler(incoming);
			outgoing.chunked().forEach(chunk -> {
				client.send(Binary(chunk));
				Resume;
			}).eager();
		});
	}
		
	public function close():Promise<Noise> {
		return base.close();
	}
}