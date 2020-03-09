package exp.sync.transport;

using tink.io.Source;

interface Client {
	function connect(stream:RealSource):RealSource;
}