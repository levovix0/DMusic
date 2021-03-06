#pragma once
#define PY_SSIZE_T_CLEAN
#include <Python.h>
#include <QString>
#include <QVector>
#include <QList>
#include <string>
#include <vector>
#include <map>
#include <stdexcept>

//TODO: mutex
namespace py
{

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

    object operator<(object const& a) const;

    PyObject* raw;
  };

  struct py_error : std::exception
  {
    std::string type;
    py_error(object type, object value, object traceback);

    char const* what() const throw() override;
  };

  struct module : object
  {
    ~module() override;
    module(module const& copy);
    module(char const* name);
    module(object name);
    module(PyObject* raw);

    module& operator=(module const& copy);


    module submodule(object name);
    module operator/(object name) { return submodule(name); }
    static module main();
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
    if (raw != nullptr && raw != Py_None) {
      Py_DECREF(raw);
    }
  }

  inline object::object(object const& copy)
  {
    raw = copy.raw;
    Py_INCREF(raw);
  }

  inline object& object::operator=(object const& copy)
  {
    raw = copy.raw;
    Py_INCREF(raw);
    return *this;
  }


  template<typename T>
  object::object(T const& o)
  {
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
    T res;
    fromPyObject(*this, res);
    return res;
  }


  inline void fromPyObject(object const& a, std::string& res)
  {
    auto repr = PyObject_Str(a.raw);
    if (!repr) repr = PyObject_Repr(a.raw);
    auto enc = PyUnicode_AsEncodedString(repr, "utf-8", "~E~");
    res = std::string(PyBytes_AS_STRING(enc));
    Py_DECREF(enc);
    Py_DECREF(repr);
  }
  inline void fromPyObject(object const& a, QString& res)
  {
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
    } else if (a.raw == Py_None || a.raw == nullptr) {
      res = 0;
    } else {
      throw std::runtime_error("unimplemented cast to int (" + a.to<std::string>() + ")");
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
    return maybe_exception(PyObject_GetAttr(raw, name.raw));
  }


  inline object object::operator()(std::initializer_list<object> const& args) const
  {
    return maybe_exception(PyObject_Call(raw, object(args).raw, nullptr));
  }

  inline object object::operator()(object arg) const
  {
    return maybe_exception(PyObject_CallOneArg(raw, arg.raw));
  }

  inline object object::operator()() const
  {
    return maybe_exception(PyObject_CallNoArgs(raw));
  }

  inline object object::operator()(std::initializer_list<object> const& args, std::map<std::string, object> const& kwargs) const
  {
    return maybe_exception(PyObject_Call(raw, object(args).raw, object(kwargs).raw));
  }

  inline object object::operator()(object arg, std::map<std::string, object> const& kwargs) const
  {
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

  inline object object::operator<(const object& a) const
  {
    return this->call("__lt__", a);
  }


  inline module::~module()
  {
    raw = nullptr; // утечка памяти?
  }

  inline module::module(const module& copy) : object()
  {
    raw = copy.raw;
    Py_INCREF(raw);
  }

  inline module::module(char const* name)
  {
    raw = PyImport_ImportModule(name);
    if (raw == nullptr) throw std::runtime_error("can't import module");
  }

  inline module::module(object name) : module(name.to<std::string>().c_str()) {}

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
    return PyImport_AddModule("__main__");
  }


  inline py_error::py_error(object type, object value, object traceback)
  {
    (void)value;
    (void)traceback;
    this->type = type.get("__name__").to<std::string>();
  }

  inline const char* py_error::what() const throw()
  {
    return type.c_str();
  }

}
