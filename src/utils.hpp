#pragma once
#include <QFutureWatcher>
#include <QJSValue>
#include <QJSEngine>
#include <QtConcurrent/QtConcurrent>


template<class T>
void move_to_thread(T& a, QThread* target) { Q_UNUSED(a); Q_UNUSED(target); }

template<class T>
void move_to_thread(T*& a, QThread* target) {
  a->moveToThread(target);
}

template<class T>
void move_to_thread(QVector<T*>& a, QThread* target) {
  for (auto&& v : a) {
    v->moveToThread(target);
  }
}
template<class T>
void move_to_thread(QList<T*>& a, QThread* target) {
  for (auto&& v : a) {
    v->moveToThread(target);
  }
}
template<class A, class B>
void move_to_thread(std::pair<A*, B*>& a, QThread* target) {
  a.first->moveToThread(target);
  a.second->moveToThread(target);
}


template<class T>
void move_to_current_thread(T& a) {
  move_to_thread(a, QThread::currentThread());
}


inline void do_async(std::function<void()> f) {
  std::thread(f).detach();
}


template<class T, class C, class... Args>
void do_async(C* obj, QJSValue const& callback, T(C::* f)(Args...), Args... args) {
  auto *watcher = new QFutureWatcher<T>;
  QObject::connect(watcher, &QFutureWatcher<T>::finished, obj,
                   [obj, watcher, callback]() {
    T res = watcher->result();
    QJSValue cbCopy(callback); // needed as callback is captured as const
    QJSEngine *engine = qjsEngine(obj);
    cbCopy.call(QJSValueList{ engine->toScriptValue(res) });
    watcher->deleteLater();
  });
  watcher->setFuture(QtConcurrent::run(obj, f, args...));
}

template<class T, class B, class C, class... Args>
void do_async(C* obj, QJSValue const& callback, std::pair<T, B>(C::* f)(Args...), Args... args) {
  auto *watcher = new QFutureWatcher<std::pair<T, B>>;
  QObject::connect(watcher, &QFutureWatcher<std::pair<T, B>>::finished, obj,
                   [obj, watcher, callback]() {
    std::pair<T, B> res = watcher->result();
    QJSValue cbCopy(callback); // needed as callback is captured as const
    QJSEngine *engine = qjsEngine(obj);
    cbCopy.call(QJSValueList{ engine->toScriptValue(res.first), engine->toScriptValue(res.second) });
    watcher->deleteLater();
  });
  watcher->setFuture(QtConcurrent::run(obj, f, args...));
}

inline QString join(QVector<QString> const& a, QString const& sep = " ") {
  if (a.isEmpty()) return "";
  QString res;
  res.reserve((a.length() - 1) * sep.length());
  res.append(a[0]);
  for (int i = 1; i < a.length(); ++i) {
    res.append(sep);
    res.append(a[i]);
  }
  return res;
}

template<class T>
inline QJsonArray toQJsonArray(QVector<T> const& a) {
  QJsonArray res;
  for (auto&& e : a)
    res.append(e);
  return res;
}