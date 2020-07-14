package coconut.sync;

enum Change<F, M> {
	Full(v:F);
	Member(v:M);
}