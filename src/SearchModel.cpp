#include "SearchModel.hpp"

#include <QNetworkRequest>
#include <QNetworkAccessManager>
#include <QNetworkReply>

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
        auto req = QNetworkRequest();
        auto manager = QNetworkAccessManager();

        auto url = QUrl("https://api.music.yandex.net/search");
        url.setQuery({ QPair{"text", request}, QPair{"type", "all"}, QPair{"page", "0"} });
        req.setUrl(url);

        req.setHeader(QNetworkRequest::UserAgentHeader, "Yandex-Music-API");
        req.setRawHeader("Accept-Language", "ru");
        req.setRawHeader("Authorization", ("OAuth " + Config::ym_token()).toUtf8());

        auto reply = manager.get(req);
        QEventLoop eventLoop;
        QObject::connect(reply, SIGNAL(finished()), &eventLoop, SLOT(quit()));
        eventLoop.exec();

        auto data = QJsonDocument::fromJson(reply->readAll()).object();
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
      } catch (std::exception& e) {
        Messages::error(tr("Failed to search"), e.what());
      }
    }

    return result;
  });

  _searchingWatcher.setFuture(_searchingFuture);
}
