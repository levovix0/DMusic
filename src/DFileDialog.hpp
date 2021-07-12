#pragma once
#include <QObject>
#include <QUrl>

class DFileDialog : public QObject
{
  Q_OBJECT
public:
  explicit DFileDialog(QObject *parent = nullptr);

public slots:
	QUrl openFile(QString filter = "*", QString title = tr("Open file"));
	QList<QUrl> openFiles(QString filter = "*", QString title = tr("Open file"));

	bool checkFilter(QString file, QString filter);

signals:

};

