import 'dart:collection';

class RingBuffer<T> {
  final int capacity;
  final ListQueue<T> _q = ListQueue<T>();

  RingBuffer({required this.capacity});

  void add(T item) {
    _q.addLast(item);
    while (_q.length > capacity) _q.removeFirst();
  }

  List<T> snapshot() => List<T>.unmodifiable(_q);
}
