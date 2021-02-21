#pragma once
#define PY_SSIZE_T_CLEAN
#include <Python.h>
#include <QString>
#include <string>
#include <vector>
#include <map>

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

  struct module : object
  {
    module(char const* name);
    module(object name);
    module(PyObject* raw);

    static module main();
  };



  inline PyObject* toPyObject(PyObject* o)
  {
    if (o == nullptr) {
//      PyErr_Print();
      throw std::runtime_error("got null python object");
    }
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
  T object::to() const {}


  template<>
  inline std::string object::to<std::string>() const
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
  inline QString object::to<QString>() const
  {
    auto repr = PyObject_Str(raw);
    if (!repr) repr = PyObject_Repr(raw);
    auto enc = PyUnicode_AsEncodedString(repr, "utf-8", "~E~");
    QString res(PyBytes_AS_STRING(enc));
    Py_DECREF(enc);
    Py_DECREF(repr);
    return res;
  }
  template<>
  inline bool object::to<bool>() const
  {
    return PyObject_IsTrue(raw);
  }


  inline object object::attr(object name) const
  {
    return PyObject_GetAttr(raw, name.raw);
  }


  inline object object::operator()(std::initializer_list<object> const& args) const
  {
    return PyObject_Call(raw, object(args).raw, nullptr);
  }

  inline object object::operator()(object arg) const
  {
    return PyObject_CallOneArg(raw, arg.raw);
  }

  inline object object::operator()() const
  {
    return PyObject_CallNoArgs(raw);
  }

  inline object object::operator()(std::initializer_list<object> const& args, std::map<std::string, object> const& kwargs) const
  {
    return PyObject_Call(raw, object(args).raw, object(kwargs).raw);
  }

  inline object object::operator()(object arg, std::map<std::string, object> const& kwargs) const
  {
    return PyObject_Call(raw, object(std::initializer_list<object>{arg}).raw, object(kwargs).raw);
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
    return PySequence_GetItem(raw, i);
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
