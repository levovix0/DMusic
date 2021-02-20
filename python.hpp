#pragma once
#define PY_SSIZE_T_CLEAN
#include <Python.h>
#include <QString>
#include <string>

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

    PyObject* raw;
  };

  struct module : object
  {
    module(char const* name);
  };



  inline PyObject* toPyObject(PyObject* o)
  {
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
    //TODO
  }

  inline object& object::operator=(object const& copy)
  {
    //TODO
    return *this;
  }


  template<typename T>
  object::object(T const& o)
  {
    raw = toPyObject(o);
  }


  inline module::module(char const* name)
  {
    raw = PyImport_ImportModule(name);
  }

  template<typename T>
  T object::to() {}


  template<>
  inline std::string object::to<std::string>()
  {
    auto repr = PyObject_Str(raw);
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
    auto enc = PyUnicode_AsEncodedString(repr, "utf-8", "~E~");
    QString res(PyBytes_AS_STRING(enc));
    Py_DECREF(enc);
    Py_DECREF(repr);
    return res;
  }
}
