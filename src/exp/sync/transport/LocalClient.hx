package exp.sync.transport;

using tink.io.Source;

class LocalClient implements Client {
	final server:LocalServer;
	public function new(server) {
		this.server = server;
	}
	
	public function connect(stream:RealSource):RealSource {
		return server.add(stream);
	}
}