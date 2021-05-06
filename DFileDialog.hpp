#pragma once
#include <QObject>

class DFileDialog : public QObject
{
  Q_OBJECT
public:
  explicit DFileDialog(QObject *parent = nullptr);

public slots:
  bool available();
  QString open(QString title = tr("Open file"), QString opens = tr("Open"), QString cancels = tr("Cancel"), QString filter = "", QString filterName = tr("File"));
  QString sellect(QString title = tr("Sellect file"), QString filter = "", QString filterName = tr("File")); // same as open(..., "Sellect")

signals:

};

