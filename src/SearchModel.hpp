#pragma once
#include <variant>
#include <QAbstractItemModel>
#include "Track.hpp"

class SearchModel : public QAbstractListModel
{
  Q_OBJECT
public:
  explicit SearchModel(QObject *parent = nullptr);

  int rowCount(QModelIndex const& parent) const override;
  QVariant data(QModelIndex const& index, int role) const override;
  QHash<int, QByteArray> roleNames() const override;

public slots:
  void search(QString request);

private:
  QVector<std::variant<refTrack>> _result; //TODO: albums and artsts
  QString _request;
};

