package exp.sync.transport;

typedef Binder = (handler:Handler) -> Promise<Server>;

interface Server {
	function close():Promise<Noise>;
}