#pragma once
#define PY_SSIZE_T_CLEAN
#include <Python.h>
#include <QString>
#include <string>
#include <vector>

namespace py
{

  struct object
  {
    object();
    ~object();
    object(object const& copy);
    object(object&& move);
    object& operator=(object const& copy);
    object& operator=(object&& move);

    template<typename T>
    object(T const& o);

    template<typename T>
    T to();

    object attr(object name);
    object get(object name) { return attr(name); }

    object operator()(std::initializer_list<object> args);
    object operator()();
    object operator()(object arg);

    object call(object name, std::initializer_list<object> args);
    object call(object name);
    object call(object name, object arg);

    object operator[](size_t i);

    object copy();
    object deepcopy();

    PyObject* raw;
  };

  struct module : object
  {
    module(char const* name);
    module(object name);
    module(PyObject* raw);

    static module main();
  };



  inline PyObject* toPyObject(PyObject* o)
  {
    if (o == nullptr) throw std::runtime_error("got null python object");
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
  inline PyObject* toPyObject(std::initializer_list<object> tuple)
  {
    PyObject* ty = PyTuple_New(tuple.size());
    int i = 0;
    for (auto& e : tuple) {
      PyTuple_SetItem(ty, i, e.raw);
      ++i;
    }
    return ty;
  }
  inline PyObject* toPyObject(long long v)
  {
    return PyLong_FromLong(v);
  }
  inline PyObject* toPyObject(std::vector<object> v)
  {
    PyObject* res = PyList_New(v.size());
    int i = 0;
    for (auto& e : v) {
      PyList_SetItem(res, i, e.raw);
      ++i;
    }
    return res;
  }


  inline object::object() : raw(nullptr) {}

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
    if (raw != nullptr) {

      Py_DecRef(raw);
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

  template<typename T>
  T object::to() {}


  template<>
  inline std::string object::to<std::string>()
  {
    auto repr = PyObject_Str(raw);
    if (!repr) repr = PyObject_Repr(raw);
    auto enc = PyUnicode_AsEncodedString(repr, "utf-8", "~E~");
    std::string res(PyBytes_AS_STRING(enc));
    Py_DECREF(enc);
    Py_DECREF(repr);
    return res;
  }
  template<>
  inline QString object::to<QString>()
  {
    auto repr = PyObject_Str(raw);
    if (!repr) repr = PyObject_Repr(raw);
    auto enc = PyUnicode_AsEncodedString(repr, "utf-8", "~E~");
    QString res(PyBytes_AS_STRING(enc));
    Py_DECREF(enc);
    Py_DECREF(repr);
    return res;
  }


  inline object object::attr(object name)
  {
    return PyObject_GetAttr(raw, name.raw);
  }


  inline object object::operator()(std::initializer_list<object> args)
  {
    return PyObject_Call(raw, object(args).raw, nullptr);
  }

  inline object object::operator()()
  {
    return PyObject_CallNoArgs(raw);
  }

  inline object object::operator()(object arg)
  {
    return PyObject_CallOneArg(raw, arg.raw);
  }


  inline object object::call(object name, std::initializer_list<object> args)
  {
    return attr(name)(args);
  }

  inline object object::call(object name)
  {
    return attr(name)();
  }

  inline object object::call(object name, object arg)
  {
    return attr(name)(arg);
  }

  inline object object::operator[](size_t i)
  {
    return PySequence_GetItem(raw, i);
  }

  inline object object::copy()
  {
    return module("copy").call("copy", *this);
  }

  inline object object::deepcopy()
  {
    return module("copy").call("deepcopy", *this);
  }


  inline module::module(char const* name)
  {
    raw = PyImport_ImportModule(name);
    if (raw == nullptr) throw std::runtime_error("can't import module");
  }

  inline module::module(object name) : module(name.to<std::string>().c_str()) {}

  inline module::module(PyObject* raw) : object(raw) {}

  inline module module::main()
  {
    return PyImport_AddModule("__main__");
  }
}
