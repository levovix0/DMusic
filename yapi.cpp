#include "yapi.hpp"
#include<QDebug>

using namespace py;

QTextStream& qStdOut()
{
    static QTextStream ts(stdout);
    return ts;
}

Yapi::Yapi(QObject *parent) : QObject(parent)
{
	Py_Initialize();
  ym = module("yandex_music");
}

Yapi::~Yapi()
{
	Py_FinalizeEx();
}

void Yapi::download(QString id)
{
  me = ym.call("Client", "AgAAAAAwR49zAAG8XvNMwDoyKUj6lw3xFFjPS_Y");
  object track = me.call("tracks", std::vector<object>{id.toInt()})[0];
  track.call("download", "a.mp3");
}

QString Yapi::test(QString a)
{
  py::object str = a;
  py::object str2 = str.call("upper").copy();
  return str2.to<QString>();
}
