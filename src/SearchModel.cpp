#include "SearchModel.hpp"

#include "YandexMusic.hpp"
#include "Messages.hpp"
#include "utils.hpp"

#include "nim_search.h"


SearchModel::SearchModel(QObject* parent) : QAbstractListModel(parent)
{}

int SearchModel::rowCount(QModelIndex const&) const
{
  return _result.length();
}

QVariant SearchModel::data(const QModelIndex& index, int) const
{
  if (index.row() >= _result.length()) return QVariant::Invalid;
  QVariant res;
  auto&& r = _result[index.row()];
  if (r.index() == 0) res.setValue(std::get<0>(r).data());
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
  auto thread = QThread::currentThread();

  QString json = ym_search(Config::ym_token(), request, "all");

  ResultList result;
  auto data = QJsonDocument::fromJson(json.toUtf8()).object();
  if (!data["result"].isObject()) return result;
  auto res = data["result"].toObject();
  if (!res["tracks"].isObject() || !res["tracks"].toObject()["results"].isArray()) return result;
  auto tracks = res["tracks"].toObject()["results"].toArray();

  int rc = 0;
  for (auto&& track : tracks) {
    if (rc++ >= maxResults) break;
    auto t = new YTrack(track.toObject()["id"].toInt(-1));
    t->moveToThread(thread);
    result.push_back({refTrack{t}});
  }

  _result = result;
  emit layoutChanged();
}
