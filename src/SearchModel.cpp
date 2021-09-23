#include "SearchModel.hpp"

SearchModel::SearchModel(QObject* parent) : QAbstractListModel(parent)
{

}

int SearchModel::rowCount(QModelIndex const&) const
{
  return _result.length();
}

QVariant SearchModel::data(const QModelIndex& index, int) const
{
  if (index.row() >= _result.length()) return QVariant::Invalid;
  QVariant res;
  auto&& r = _result[index.row()];
  if (r.index() == 0) res.setValue(std::get<0>(r));
  return res;
}

QHash<int, QByteArray> SearchModel::roleNames() const
{
  static QHash<int, QByteArray>* pHash = nullptr;
  if (!pHash) {
      pHash = new QHash<int, QByteArray>;
      (*pHash)[Qt::UserRole + 1] = "element";
  }
  return *pHash;
}

void SearchModel::search(QString request)
{

}
