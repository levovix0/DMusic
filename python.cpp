#include "python.hpp"
#include <stdexcept>
#include "Messages.hpp"

py::error::error(py::object type, py::object value, py::object traceback)
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

const char* py::error::what() const throw()
{
  return msg.c_str();
}


py::object::object() : raw(Py_None) {}

py::object::object(py::object&& move) : raw(move.raw)
{
  move.raw = nullptr;
}

py::object& py::object::operator=(py::object&& move)
{
  raw = move.raw;
  move.raw = nullptr;
  return *this;
}

py::object::~object()
{
  QMutexLocker locker(&mutex);
  if (raw != nullptr && raw != Py_None) {
    Py_DECREF(raw);
  }
}

py::object::object(const py::object& copy)
{
  QMutexLocker locker(&mutex);
  raw = copy.raw;
  Py_INCREF(raw);
}

py::object& py::object::operator=(const py::object& copy)
{
  QMutexLocker locker(&mutex);
  raw = copy.raw;
  Py_INCREF(raw);
  return *this;
}

py::object::Iterator::Iterator(py::object iter)
{
  this->iter = iter;
  ++(*this);
}

void py::object::Iterator::operator++()
{
  try {
    v = iter.call("__next__");
  }  catch (error& e) {
    if (e.type != "StopIteration") throw e;
    end = true;
  }
}

py::object& py::object::Iterator::operator*() { return v; }

bool py::object::Iterator::operator!=(EndIterator) { return !end; }

void py::fetchException() {
  PyObject *type, *value, *traceback;
  PyErr_Fetch(&type, &value, &traceback);
  if (type == nullptr) return;
  PyErr_Clear();
  throw error(type, value? value : nullptr, traceback? traceback : nullptr);
}

PyObject* py::maybe_exception(PyObject* a) {
  if (a == nullptr) {
    fetchException();
  }
  return a;
}

void py::maybe_exception(int a) {
  if (a != 0) {
    fetchException();
  }
}

PyObject* py::toPyObject(PyObject* o)
{
  if (o == nullptr) {
    return Py_None;
  }
  Py_INCREF(o);
  return o;
}

PyObject* py::toPyObject(const char* s)
{
  return PyUnicode_FromString(s);
}

PyObject* py::toPyObject(const std::string& s)
{
  return PyUnicode_FromString(s.c_str());
}

PyObject* py::toPyObject(const QString& s)
{
  return PyUnicode_FromString(s.toUtf8().data());
}

PyObject* py::toPyObject(const std::initializer_list<py::object>& tuple)
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

PyObject* py::toPyObject(long long v)
{
  return PyLong_FromLongLong(v);
}

PyObject* py::toPyObject(int v)
{
  return PyLong_FromLong(v);
}

PyObject* py::toPyObject(bool v)
{
  return PyBool_FromLong(v);
}

PyObject* py::toPyObject(std::nullptr_t)
{
  return Py_None; // TODO: nullptr
}

PyObject* py::toPyObject(py::none_t)
{
  return Py_None;
}

PyObject* py::toPyObject(const std::vector<py::object>& v)
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

PyObject* py::toPyObject(const std::map<std::string, py::object>& v)
{
  PyObject* res = PyDict_New();
  for (auto& e : v) {
    Py_INCREF(e.second.raw);
    PyDict_SetItem(res, object(e.first).raw, e.second.raw);
  }
  return res;
}

void py::fromPyObject(const py::object& a, py::object& res)
{
  Py_INCREF(a.raw);
  res.raw = a.raw;
}

void py::fromPyObject(const py::object& a, std::string& res)
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

void py::fromPyObject(const py::object& a, QString& res)
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

void py::fromPyObject(const py::object& a, bool& res)
{
  QMutexLocker locker(&mutex);
  res = PyObject_IsTrue(a.raw);
}

void py::fromPyObject(const py::object& a, int& res)
{
  if (PyLong_Check(a.raw)) {
    res = PyLong_AsLong(a.raw);
  } else if (PyUnicode_Check(a.raw)) {
    auto p = PyLong_FromUnicodeObject(a.raw, 10);
    if (p) {
      res = PyLong_AsLong(p);
      Py_DECREF(p);
    }
    else res = 0;
  } else if (a == none || a == nullptr) {
    res = 0;
  } else {
    throw std::runtime_error("unimplemented cast to int (" + a.to<std::string>() + ")");
  }
}

void py::fromPyObject(const py::object& a, qint64& res)
{
  if (PyLong_Check(a.raw)) {
    res = PyLong_AsLong(a.raw);
  } else if (PyUnicode_Check(a.raw)) {
    auto p = PyLong_FromUnicodeObject(a.raw, 10);
    if (p) {
      res = PyLong_AsLong(p);
      Py_DECREF(p);
    }
    else res = 0;
  } else if (a == none || a == nullptr) {
    res = 0;
  } else {
    throw std::runtime_error("unimplemented cast to qint64 (" + a.to<std::string>() + ")");
  }
}

py::object py::object::attr(py::object name) const
{
  QMutexLocker locker(&mutex);
  return maybe_exception(PyObject_GetAttr(raw, name.raw));
}

bool py::object::has(py::object name) const
{
  QMutexLocker locker(&mutex);
  return PyObject_HasAttr(raw, name.raw);
}

void py::object::set(py::object name, py::object value)
{
  QMutexLocker locker(&mutex);
  maybe_exception(PyObject_SetAttr(raw, name.raw, value.raw));
}

void py::object::del_attr(py::object name)
{
  QMutexLocker locker(&mutex);
  maybe_exception(PyObject_DelAttr(raw, name.raw));
}

py::object py::object::operator()(const std::initializer_list<py::object>& args) const
{
  QMutexLocker locker(&mutex);
  return maybe_exception(PyObject_Call(raw, object(args).raw, nullptr));
}

py::object py::object::operator()(py::object arg) const
{
  QMutexLocker locker(&mutex);
  return maybe_exception(PyObject_CallOneArg(raw, arg.raw));
}

py::object py::object::operator()() const
{
  QMutexLocker locker(&mutex);
  return maybe_exception(PyObject_CallNoArgs(raw));
}

py::object py::object::operator()(const std::initializer_list<py::object>& args, const std::map<std::string, py::object>& kwargs) const
{
  QMutexLocker locker(&mutex);
  return maybe_exception(PyObject_Call(raw, object(args).raw, object(kwargs).raw));
}

py::object py::object::operator()(py::object arg, const std::map<std::string, py::object>& kwargs) const
{
  QMutexLocker locker(&mutex);
  return maybe_exception(PyObject_Call(raw, object(std::initializer_list<object>{arg}).raw, object(kwargs).raw));
}

py::object py::object::call(py::object name, const std::initializer_list<py::object>& args) const
{
  return attr(name)(args);
}

py::object py::object::call(py::object name, py::object arg) const
{
  return attr(name)(arg);
}

py::object py::object::call(py::object name) const
{
  return attr(name)();
}

py::object py::object::call(py::object name, const std::initializer_list<py::object>& args, const std::map<std::string, py::object>& kwargs) const
{
  return attr(name)(args, kwargs);
}

py::object py::object::call(py::object name, py::object arg, const std::map<std::string, py::object>& kwargs) const
{
  return attr(name)(arg, kwargs);
}

py::object py::object::operator[](size_t i) const
{
  QMutexLocker locker(&mutex);
  return maybe_exception(PySequence_GetItem(raw, i));
}

py::object py::object::contains(py::object a) const
{
  return call("__contains__", a);
}

py::object py::object::len() const
{
  return call("__len__");
}

py::object py::object::copy() const
{
  return module("copy").call("copy", *this);
}

py::object py::object::deepcopy() const
{
  return module("copy").call("deepcopy", *this);
}

py::object& py::object::print()
{
  QMutexLocker locker(&mutex);
  PyObject_Print(raw, stdout, 0);
  return *this;
}

py::object& py::object::throw_repr()
{
  throw std::runtime_error(to<std::string>());
  return *this;
}

py::object py::object::operator!()
{
  QMutexLocker locker(&mutex);
  return PyObject_Not(raw);
}

py::object py::object::operator<(const py::object& a) const
{
  return this->call("__lt__", a);
}

bool py::object::operator==(py::none_t) const
{
  return raw == Py_None;
}

bool py::object::operator==(std::nullptr_t) const
{
  return raw == nullptr;
}

bool py::object::operator!=(py::none_t) const
{
  return raw != Py_None;
}

bool py::object::operator!=(std::nullptr_t) const
{
  return raw != nullptr;
}

py::object::Iterator py::object::begin() const
{
  return {call("__iter__")};
}

py::object::EndIterator py::object::end() const
{
  return {};
}

py::module::~module()
{
  raw = nullptr; // утечка памяти?
}

py::module::module(const py::module& copy) : object()
{
  QMutexLocker locker(&mutex);
  raw = copy.raw;
  Py_INCREF(raw);
}

py::module::module(const char* name, bool autoInstall)
{
  QMutexLocker locker(&mutex);
  raw = PyImport_ImportModule(name);
  if (raw == nullptr) {
    Messages::message(QObject::tr("Failed to import python module '%1', it will be auto-installed").arg(name));
    if (autoInstall) {
      if (module::autoInstall(name)) {
        raw = PyImport_ImportModule(name);
        if (raw != nullptr) return;
      }
    }
    throw std::runtime_error(std::string("python: can't import module '") + name + "'");
  }
}

py::module::module(py::object name, bool autoInstall) : module(name.to<std::string>().c_str(), autoInstall) {}

py::module::module(PyObject* raw) : object(raw) {}

py::module& py::module::operator=(const py::module& copy)
{
  raw = copy.raw;
  return *this;
}

py::module py::module::submodule(py::object name)
{
  return module(get(name).raw);
}

py::module py::module::main()
{
  QMutexLocker locker(&mutex);
  return PyImport_AddModule("__main__");
}

bool py::module::autoInstall(py::object name)
{
  try {
    auto pip = module("pip");
    pip.call("main", std::vector<object>{"install", name});
    return true;
  }  catch (std::exception const& e) {
    Messages::error(QObject::tr("Failed to auto-install python module '%1'").arg(name), e.what());
    return false;
  }
}
