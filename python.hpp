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
#include <stdexcept>
#include <iostream>

namespace py
{
// TODO: итератор по списку
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

    PyObject* raw;
  };

  struct py_error : std::exception
  {
    std::string type;
    object value;

    py_error(object type, object value, object traceback);

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



  inline PyObject* toPyObject(PyObject* o)
  {
    if (o == nullptr) {
      return Py_None;
    }
    Py_INCREF(o);
    return o;
  }

  inline PyObject* toPyObject(char const* s)
  {
    return PyUnicode_FromString(s);
  }
  inline PyObject* toPyObject(std::string const& s)
  {
    return PyUnicode_FromString(s.c_str());
  }
  inline PyObject* toPyObject(QString const& s)
  {
    return PyUnicode_FromString(s.toUtf8().data());
  }
  inline PyObject* toPyObject(std::initializer_list<object> const& tuple)
  {
    PyObject* ty = PyTuple_New(tuple.size());
    int i = 0;
    for (auto& e : tuple) {
      Py_INCREF(e.raw);
      PyTuple_SetItem(ty, i, e.raw);
      ++i;
    }
    return ty;
  }
  inline PyObject* toPyObject(long long v)
  {
    return PyLong_FromLongLong(v);
  }
  inline PyObject* toPyObject(int v)
  {
    return PyLong_FromLong(v);
  }
  inline PyObject* toPyObject(bool v)
  {
    return PyBool_FromLong(v);
  }
  inline PyObject* toPyObject(std::nullptr_t)
  {
    return Py_None; // TODO: nullptr
  }
  inline PyObject* toPyObject(none_t)
  {
    return Py_None;
  }
  inline PyObject* toPyObject(std::vector<object> const& v)
  {
    PyObject* res = PyList_New(v.size());
    int i = 0;
    for (auto& e : v) {
      Py_INCREF(e.raw);
      PyList_SetItem(res, i, e.raw);
      ++i;
    }
    return res;
  }
  inline PyObject* toPyObject(std::map<std::string, object> const& v)
  {
    PyObject* res = PyDict_New();
    for (auto& e : v) {
      Py_INCREF(e.second.raw);
      PyDict_SetItem(res, object(e.first).raw, e.second.raw);
    }
    return res;
  }


  inline object::object() : raw(Py_None) {}

  inline object::object(object&& move) : raw(move.raw)
  {
    move.raw = nullptr;
  }

  inline object& object::operator=(object&& move)
  {
    raw = move.raw;
    move.raw = nullptr;
    return *this;
  }

  inline object::~object()
  {
    QMutexLocker locker(&mutex);
    if (raw != nullptr && raw != Py_None) {
      Py_DECREF(raw);
    }
  }

  inline object::object(object const& copy)
  {
    QMutexLocker locker(&mutex);
    raw = copy.raw;
    Py_INCREF(raw);
  }

  inline object& object::operator=(object const& copy)
  {
    QMutexLocker locker(&mutex);
    raw = copy.raw;
    Py_INCREF(raw);
    return *this;
  }


  template<typename T>
  object::object(T const& o)
  {
    QMutexLocker locker(&mutex);
    raw = toPyObject(o);
  }


  inline void fetchException() {
    PyObject *type, *value, *traceback;
    PyErr_Fetch(&type, &value, &traceback);
    if (type == nullptr) return;
    PyErr_Clear();
    throw py_error(type, value? value : nullptr, traceback? traceback : nullptr);
  }

  inline PyObject* maybe_exception(PyObject* a) {
    if (a == nullptr) {
       fetchException();
    }
    return a;
  }


  template<typename T>
  T object::to() const {
    QMutexLocker locker(&mutex);
    T res;
    fromPyObject(*this, res);
    return res;
  }


  inline void fromPyObject(object const& a, object& res)
  {
    Py_INCREF(a.raw);
    res.raw = a.raw;
  }
  inline void fromPyObject(object const& a, std::string& res)
  {
    if (a == none) {
      res = "";
      return;
    }
    auto repr = PyObject_Str(a.raw);
    if (!repr) repr = PyObject_Repr(a.raw);
    auto enc = PyUnicode_AsEncodedString(repr, "utf-8", "~E~");
    res = std::string(PyBytes_AS_STRING(enc));
    Py_DECREF(enc);
    Py_DECREF(repr);
  }
  inline void fromPyObject(object const& a, QString& res)
  {
    if (a == none) {
      res = "";
      return;
    }
    auto repr = PyObject_Str(a.raw);
    if (!repr) repr = PyObject_Repr(a.raw);
    auto enc = PyUnicode_AsEncodedString(repr, "utf-8", "~E~");
    res = QString(PyBytes_AS_STRING(enc));
    Py_DECREF(enc);
    Py_DECREF(repr);
  }
  inline void fromPyObject(object const& a, bool& res)
  {
    res = PyObject_IsTrue(a.raw);
  }
  inline void fromPyObject(object const& a, int& res)
  {
    if (PyLong_Check(a.raw)) {
      res = PyLong_AsLong(a.raw);
    } else if (PyUnicode_Check(a.raw)) {
      res = PyLong_AsLong(PyLong_FromUnicodeObject(a.raw, 10));
    } else if (a == none || a == nullptr) {
      res = 0;
    } else {
      throw std::runtime_error("unimplemented cast to int (" + a.to<std::string>() + ")");
    }
  }
  inline void fromPyObject(object const& a, qint64& res)
  {
    if (PyLong_Check(a.raw)) {
      res = PyLong_AsLong(a.raw);
    } else if (PyUnicode_Check(a.raw)) {
      res = PyLong_AsLong(PyLong_FromUnicodeObject(a.raw, 10));
    } else if (a == none || a == nullptr) {
      res = 0;
    } else {
      throw std::runtime_error("unimplemented cast to long (" + a.to<std::string>() + ")");
    }
  }

  template<class T>
  inline void fromPyObject(object const& a, QVector<T>& res)
  {
    if (!PyList_Check(a.raw)) {
      res.resize(0);
      return;
    }
    res.resize(PyList_Size(a.raw));
    size_t i = 0;
    for (auto&& r : res) {
      fromPyObject(PyList_GetItem(a.raw, i), r);
      ++i;
    }
  }

  template<class T>
  inline void fromPyObject(object const& a, QList<T>& res)
  {
    res = QList<T>();
    if (!PyList_Check(a.raw)) return;

    size_t n = PyList_Size(a.raw);
    for (size_t i = 0; i < n; ++i) {
      T o;
      fromPyObject(PyList_GetItem(a.raw, i), o);
      res.append(o);
    }
  }


  inline object object::attr(object name) const
  {
    QMutexLocker locker(&mutex);
    return maybe_exception(PyObject_GetAttr(raw, name.raw));
  }

  inline bool object::has(object name) const
  {
    QMutexLocker locker(&mutex);
    return PyObject_HasAttr(raw, name.raw);
  }


  inline object object::operator()(std::initializer_list<object> const& args) const
  {
    QMutexLocker locker(&mutex);
    return maybe_exception(PyObject_Call(raw, object(args).raw, nullptr));
  }

  inline object object::operator()(object arg) const
  {
    QMutexLocker locker(&mutex);
    return maybe_exception(PyObject_CallOneArg(raw, arg.raw));
  }

  inline object object::operator()() const
  {
    QMutexLocker locker(&mutex);
    return maybe_exception(PyObject_CallNoArgs(raw));
  }

  inline object object::operator()(std::initializer_list<object> const& args, std::map<std::string, object> const& kwargs) const
  {
    QMutexLocker locker(&mutex);
    return maybe_exception(PyObject_Call(raw, object(args).raw, object(kwargs).raw));
  }

  inline object object::operator()(object arg, std::map<std::string, object> const& kwargs) const
  {
    QMutexLocker locker(&mutex);
    return maybe_exception(PyObject_Call(raw, object(std::initializer_list<object>{arg}).raw, object(kwargs).raw));
  }


  inline object object::call(object name, std::initializer_list<object> const& args) const
  {
    return attr(name)(args);
  }

  inline object object::call(object name, object arg) const
  {
    return attr(name)(arg);
  }

  inline object object::call(object name) const
  {
    return attr(name)();
  }

  inline object object::call(object name, std::initializer_list<object> const& args, std::map<std::string, object> const& kwargs) const
  {
    return attr(name)(args, kwargs);
  }

  inline object object::call(object name, object arg, std::map<std::string, object> const& kwargs) const
  {
    return attr(name)(arg, kwargs);
  }

  inline object object::operator[](size_t i) const
  {
    QMutexLocker locker(&mutex);
    return maybe_exception(PySequence_GetItem(raw, i));
  }

  inline object object::copy() const
  {
    return module("copy").call("copy", *this);
  }

  inline object object::deepcopy() const
  {
    return module("copy").call("deepcopy", *this);
  }

  inline object& object::print()
  {
    PyObject_Print(raw, stdout, 0);
    return *this;
  }

  inline object& object::throw_repr()
  {
    throw std::runtime_error(to<std::string>());
    return *this;
  }

  inline object object::operator<(const object& a) const
  {
    return this->call("__lt__", a);
  }

  inline bool object::operator==(none_t) const
  {
    return raw == Py_None;
  }
  inline bool object::operator==(std::nullptr_t) const
  {
    return raw == nullptr;
  }
  inline bool object::operator!=(none_t) const
  {
    return raw != Py_None;
  }
  inline bool object::operator!=(std::nullptr_t) const
  {
    return raw != nullptr;
  }


  inline module::~module()
  {
    raw = nullptr; // утечка памяти?
  }

  inline module::module(const module& copy) : object()
  {
    QMutexLocker locker(&mutex);
    raw = copy.raw;
    Py_INCREF(raw);
  }

  inline module::module(char const* name, bool autoInstall)
  {
    QMutexLocker locker(&mutex);
    raw = PyImport_ImportModule(name);
    if (raw == nullptr) {
      std::cerr << "failed to import python module '" << name << "', trying to auto-install..." << std::endl;
      if (autoInstall) {
        if (module::autoInstall(name)) {
          raw = PyImport_ImportModule(name);
          if (raw != nullptr) return;
        }
      }
      throw std::runtime_error(std::string("python: can't import module '") + name + "'");
    }
  }

  inline module::module(object name, bool autoInstall) : module(name.to<std::string>().c_str(), autoInstall) {}

  inline module::module(PyObject* raw) : object(raw) {}

  inline module& module::operator=(const module& copy)
  {
    raw = copy.raw;
    return *this;
  }

  inline module module::submodule(object name)
  {
    return module(get(name).raw);
  }

  inline module module::main()
  {
    QMutexLocker locker(&mutex);
    return PyImport_AddModule("__main__");
  }

  inline bool module::autoInstall(object name)
  {
    try {
      auto pip = module("pip");
      pip.call("main", std::vector<object>{"install", name});
      return true;
    }  catch (std::exception const& e) {
      std::cerr << "failed to auto-install python module '" << name << "': " << e.what() << std::endl;
      return false;
    }
  }


  inline py_error::py_error(object type, object value, object traceback)
  {
    this->type = type.get("__name__").to<std::string>();
    this->value = value;
    (void)traceback;

    if (value == none) {
      msg = this->type;
    } else {
      msg = value.to<std::string>() + " [" + this->type + "]";
    }
  }

  inline const char* py_error::what() const throw()
  {
    return msg.c_str();
  }
}
