#pragma once
#include <QObject>
#include <QQmlEngine>
#include <QJSEngine>

class Messages : public QObject
{
  Q_OBJECT
public:
  explicit Messages(QObject *parent = nullptr);

  static Messages* instance;
  static Messages* qmlInstance(QQmlEngine*, QJSEngine*);

  static void message(QString text, QString details = "");
  static void error(QString text, QString details = "");

  struct Message { QString text, details; bool isError; };
  QVector<Message> history;

public slots:
  void sendMessage(QString text, QString details = "");
  void sendError(QString text, QString details = "");
  void reSendHistory();

signals:
  void gotMessage(QString text, QString details);
  void gotError(QString text, QString details);

};
