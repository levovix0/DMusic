#pragma once
#undef slots
#define PY_SSIZE_T_CLEAN
#include <Python.h>
#define slots Q_SLOTS

#include <QString>
#include <QVector>
#include <QList>
#include <QMutex>
#include <QMutexLocker>
#include <string>
#include <vector>
#include <map>

namespace py
{
  inline QMutex mutex(QMutex::Recursive);

  struct none_t {};
  inline static const none_t none;

  struct object
  {
    object();
    virtual ~object();
    object(object const& copy);
    object(object&& move);
    object& operator=(object const& copy);
    object& operator=(object&& move);

    template<typename T>
    object(T const& o);

    template<typename T>
    T to() const;

    object attr(object name) const;
    object get(object name) const { return attr(name); }
    bool has(object name) const;

    object operator()(std::initializer_list<object> const& args) const;
    object operator()(object arg) const;
    object operator()() const;
    object operator()(std::initializer_list<object> const& args, std::map<std::string, object> const& kwargs) const;
    object operator()(object arg, std::map<std::string, object> const& kwargs) const;

    object call(object name, std::initializer_list<object> const& args) const;
    object call(object name, object arg) const;
    object call(object name) const;
    object call(object name, std::initializer_list<object> const& args, std::map<std::string, object> const& kwargs) const;
    object call(object name, object arg, std::map<std::string, object> const& kwargs) const;

    object operator[](size_t i) const;
    object contains(object a) const;
    object len() const;

    object copy() const;
    object deepcopy() const;

    object& print();
    object& throw_repr();

    operator bool() { return to<bool>(); }

    object operator<(object const& a) const;
    bool operator==(none_t) const;
    bool operator==(std::nullptr_t) const;
    bool operator!=(none_t) const;
    bool operator!=(std::nullptr_t) const;

    struct Iterator;
    struct EndIterator {};

    Iterator begin() const;
    EndIterator end() const;

    PyObject* raw;
  };

  struct error : std::exception
  {
    std::string type;
    object value;

    error(object type, object value, object traceback);

    std::string msg;
    char const* what() const throw() override;
  };

  struct module : object
  {
    ~module() override;
    module(module const& copy);
    module(char const* name, bool autoInstall = false);
    module(object name, bool autoInstall = false);
    module(PyObject* raw);

    module& operator=(module const& copy);

    module submodule(object name);
    module operator/(object name) { return submodule(name); }
    static module main();
    static bool autoInstall(object name); // auto-install module using pip
  };

  struct object::Iterator
  {
    object iter;
    Iterator(object iter);
    bool end = false;
    object v;
    void operator++();
    object& operator*();
    bool operator!=(EndIterator);
  };

  void fetchException();
  PyObject* maybe_exception(PyObject* a);

  PyObject* toPyObject(PyObject* o);
  PyObject* toPyObject(char const* s);
  PyObject* toPyObject(std::string const& s);
  PyObject* toPyObject(QString const& s);
  PyObject* toPyObject(std::initializer_list<object> const& tuple);
  PyObject* toPyObject(long long v);
  PyObject* toPyObject(int v);
  PyObject* toPyObject(bool v);
  PyObject* toPyObject(std::nullptr_t);
  PyObject* toPyObject(none_t);
  PyObject* toPyObject(std::vector<object> const& v);
  PyObject* toPyObject(std::map<std::string, object> const& v);

  template<typename T>
  object::object(T const& o)
  {
    QMutexLocker locker(&mutex);
    raw = toPyObject(o);
  }

  template<typename T>
  T object::to() const {
    QMutexLocker locker(&mutex);
    T res;
    fromPyObject(*this, res);
    return res;
  }

  void fromPyObject(object const& a, object& res);
  void fromPyObject(object const& a, std::string& res);
  void fromPyObject(object const& a, QString& res);
  void fromPyObject(object const& a, bool& res);
  void fromPyObject(object const& a, int& res);
  void fromPyObject(object const& a, qint64& res);

  template<class T>
  inline void fromPyObject(object const& a, QVector<T>& res)
  {
    res = QVector<T>();
    for (auto&& p : a) {
      res.append(p.to<T>());
    }
  }

  template<class T>
  inline void fromPyObject(object const& a, QList<T>& res)
  {
    res = QList<T>();
    for (auto&& p : a) {
      res.append(p.to<T>());
    }
  }
}
