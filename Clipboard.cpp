#include "Clipboard.hpp"
#include <QGuiApplication>

Clipboard::Clipboard(QObject *parent) : QObject(parent), _clipboard(QGuiApplication::clipboard())
{

}

void Clipboard::copy(QString text)
{
  _clipboard->setText(text);
}
