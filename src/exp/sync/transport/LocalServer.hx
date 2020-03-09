package exp.sync.transport;

using tink.io.Source;

class LocalServer implements Server {
	public static function bind(handler:Handler):Promise<Server> {
		var server = new LocalServer(handler);
		return Promise.resolve((server:Server));
	}
	
	final handler:Handler;
	
	function new(handler) {
		this.handler = handler;
	}
	
	public function add(incoming:RealSource):RealSource {
		return handler(incoming);
	}
		
	public function close():Promise<Noise> {
		return new Error('TODO');
	}
}