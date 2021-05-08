#include "Messages.hpp"

Messages* Messages::instance = new Messages;

Messages::Messages(QObject *parent) : QObject(parent)
{

}

Messages* Messages::qmlInstance(QQmlEngine*, QJSEngine*)
{
  return instance;
}

void Messages::message(QString text, QString details)
{
  instance->sendMessage(text, details);
}

void Messages::error(QString text, QString details)
{
  instance->sendError(text, details);
}

void Messages::sendMessage(QString text, QString details)
{
  emit gotMessage(text, details);
}

void Messages::sendError(QString text, QString details)
{
  emit gotError(text, details);
}
