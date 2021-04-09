#pragma once
#include <QObject>
#include <QClipboard>

class Clipboard : public QObject
{
  Q_OBJECT
public:
  explicit Clipboard(QObject *parent = nullptr);

public slots:
  void copy(QString text);

private:
  QClipboard* _clipboard;
};

