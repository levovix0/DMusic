#pragma once
#include <variant>
#include <QAbstractItemModel>
#include <QFutureWatcher>
#include "Track.hpp"

class SearchModel : public QAbstractListModel
{
  Q_OBJECT
  using ResultList = QVector<std::variant<refTrack>>;
public:
  explicit SearchModel(QObject *parent = nullptr);

  int rowCount(QModelIndex const& parent) const override;
  QVariant data(QModelIndex const& index, int role) const override;
  QHash<int, QByteArray> roleNames() const override;

public slots:
  void search(QString request);

private:
  static constexpr int maxResults = 5;

  ResultList _result; //TODO: albums and artsts
  QString _request;

  std::atomic_bool _searcing;
  QFuture<ResultList> _searchingFuture;
  QFutureWatcher<ResultList> _searchingWatcher;
};

