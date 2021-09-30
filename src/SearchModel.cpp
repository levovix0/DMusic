#include "SearchModel.hpp"
#include "YandexMusic.hpp"
#include "Messages.hpp"
#include "utils.hpp"

SearchModel::SearchModel(QObject* parent) : QAbstractListModel(parent)
{
  connect(&_searchingWatcher, &QFutureWatcher<ResultList>::finished, this, [this] {
    _result = _searchingWatcher.result();
    emit layoutChanged();
    _searcing = false;
  }, Qt::QueuedConnection);
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
  if (_searcing) {
    _searchingFuture.cancel();
  }
  _searcing = true;

  auto yc = YClient::instance->me;
  auto thread = QThread::currentThread();

  // поскольку питон - однопоточное говно, это распараллеливание не имеет смысла
  // TODO: делать поисковой запрос без питона
  _searchingFuture = QtConcurrent::run([request, yc, thread]() -> ResultList {
    ResultList result;

    if (request.isEmpty()) {
      return result;
    }

    if (YClient::instance->initialized()) {
      try {
        auto r = yc.call("search", request);
        if (r.get("tracks")) {
          int rc = 0;
          for (auto&& track : r.get("tracks").get("results")) {
            if (rc++ >= maxResults) break;
            auto t = new YTrack(track);
            t->moveToThread(thread);
            result.push_back({refTrack{t}});
          }
        }
      } catch (std::exception& e) {
        Messages::error(tr("Failed to search"), e.what());
      }
    }

    return result;
  });

  _searchingWatcher.setFuture(_searchingFuture);
}
