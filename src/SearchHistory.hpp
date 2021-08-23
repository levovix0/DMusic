#pragma once
#include <QAbstractListModel>
#include <QQmlEngine>
#include <QJSEngine>

class SearchHistory : public QAbstractListModel
{
  Q_OBJECT
public:
  explicit SearchHistory(QObject *parent = nullptr);

  static SearchHistory* instance;
  static SearchHistory* qmlInstance(QQmlEngine*, QJSEngine*);

  int rowCount(const QModelIndex& parent) const override;
  QVariant data(const QModelIndex& index, int role) const override;
  QHash<int, QByteArray> roleNames() const override;

public slots:
  void savePromit(QString promit);

private slots:
  void load();
  void save();

private:
  static constexpr int maxLenght = 5;
  QStringList _history;
};

