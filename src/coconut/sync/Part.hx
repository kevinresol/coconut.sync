package coconut.sync;

enum Part<F, M> {
	Full(v:F);
	Member(v:M);
}