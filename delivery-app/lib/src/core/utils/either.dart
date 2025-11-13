abstract class Either<L, R> {
  const Either();

  bool get isLeft => this is Left<L, R>;
  bool get isRight => this is Right<L, R>;

  L? get left => isLeft ? (this as Left<L, R>).value : null;
  R? get right => isRight ? (this as Right<L, R>).value : null;

  T fold<T>(T Function(L left) onLeft, T Function(R right) onRight) {
    if (this is Left<L, R>) {
      return onLeft((this as Left<L, R>).value);
    } else {
      return onRight((this as Right<L, R>).value);
    }
  }

  Either<L, T> map<T>(T Function(R right) mapper) {
    return fold(
      (left) => Left<L, T>(left),
      (right) => Right<L, T>(mapper(right)),
    );
  }

  Either<T, R> mapLeft<T>(T Function(L left) mapper) {
    return fold(
      (left) => Left<T, R>(mapper(left)),
      (right) => Right<T, R>(right),
    );
  }
}

class Left<L, R> extends Either<L, R> {
  final L value;

  const Left(this.value);
}

class Right<L, R> extends Either<L, R> {
  final R value;

  const Right(this.value);
}
